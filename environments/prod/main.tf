################################################################################
# Tags
################################################################################

module "tags" {
  source = "git::https://github.com/venky1912/venky-terraform-module-tags.git?ref=v0.1.0"

  project     = var.project_name
  environment = var.environment
  owner       = var.owner
  region      = var.region
  criticality = var.environment == "prod" ? "critical" : "medium"
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source = "git::https://github.com/venky1912/venky-terraform-module-vpc.git?ref=v0.1.3"

  name               = "${var.project_name}-${var.environment}"
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway

  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  interface_endpoints      = ["ec2", "ecr.api", "ecr.dkr", "sts", "logs", "elasticloadbalancing"]

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                              = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb"                                       = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "shared"
  }

  tags = module.tags.tags
}

################################################################################
# IAM
################################################################################

module "iam" {
  source = "git::https://github.com/venky1912/venky-terraform-module-iam.git?ref=v1.0.1"

  name = "${var.project_name}-${var.environment}"

  roles = {
    eks-cluster = {
      description = "EKS cluster role"
      trust_policy_statements = [{
        actions   = ["sts:AssumeRole"]
        principal = { Service = "eks.amazonaws.com" }
      }]
      policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
        "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
      ]
    }
    eks-node = {
      description = "EKS managed node group role"
      trust_policy_statements = [{
        actions   = ["sts:AssumeRole"]
        principal = { Service = "ec2.amazonaws.com" }
      }]
      policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      ]
      create_instance_profile = true
    }
  }

  tags = module.tags.tags
}

################################################################################
# Security (KMS + Security Groups)
################################################################################

module "security" {
  source = "git::https://github.com/venky1912/venky-terraform-module-security.git?ref=v1.0.1"

  name = "${var.project_name}-${var.environment}"

  kms_keys = {
    eks = { description = "EKS secrets encryption" }
  }

  security_groups = {
    eks-cluster = {
      vpc_id      = module.vpc.vpc_id
      description = "EKS cluster control plane"
      ingress_rules = {
        nodes-api = {
          description = "Allow nodes to reach API server"
          from_port   = 443
          to_port     = 443
          ip_protocol = "tcp"
          cidr_ipv4   = var.vpc_cidr
        }
      }
      egress_rules = {
        all = {
          description = "Allow all egress"
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }
    }
    eks-node = {
      vpc_id      = module.vpc.vpc_id
      description = "EKS worker nodes"
      ingress_rules = {
        cluster-to-nodes = {
          description = "Cluster to nodes (kubelet + workloads)"
          from_port   = 1025
          to_port     = 65535
          ip_protocol = "tcp"
          cidr_ipv4   = var.vpc_cidr
        }
        cluster-to-nodes-https = {
          description = "Cluster to nodes HTTPS (webhooks)"
          from_port   = 443
          to_port     = 443
          ip_protocol = "tcp"
          cidr_ipv4   = var.vpc_cidr
        }
        node-to-node = {
          description = "Node to node communication"
          from_port   = 0
          to_port     = 65535
          ip_protocol = "-1"
          cidr_ipv4   = var.vpc_cidr
        }
      }
      egress_rules = {
        all = {
          description = "Allow all egress"
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }
    }
  }

  tags = module.tags.tags
}

################################################################################
# EKS Cluster
################################################################################

module "eks" {
  source = "git::https://github.com/venky1912/venky-terraform-module-eks.git?ref=v0.2.1"

  name               = "${var.project_name}-${var.environment}"
  cluster_version    = var.cluster_version
  cluster_role_arn   = module.iam.role_arns["eks-cluster"]
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security.security_group_ids["eks-cluster"]]

  cluster_type                         = var.cluster_type
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  cluster_encryption_kms_key_arn = module.security.kms_key_arns["eks"]

  # Hybrid configuration (only used when cluster_type = "hybrid")
  remote_network_config = var.cluster_type == "hybrid" ? {
    remote_node_cidrs = var.remote_node_cidrs
    remote_pod_cidrs  = var.remote_pod_cidrs
  } : null

  hybrid_node_role_arn = var.cluster_type == "hybrid" ? module.hybrid_node_role[0].role_arn : null

  managed_node_groups = {
    general = {
      node_role_arn  = module.iam.role_arns["eks-node"]
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      disk_size      = var.node_disk_size
      labels         = { workload = "general", environment = var.environment }
    }
  }

  tags = module.tags.tags
}

################################################################################
# Hybrid Node Role (only when cluster_type = "hybrid")
################################################################################

module "hybrid_node_role" {
  count  = var.cluster_type == "hybrid" ? 1 : 0
  source = "git::https://github.com/venky1912/venky-terraform-module-eks.git//modules/hybrid-node-role?ref=v0.2.1"

  cluster_name = "${var.project_name}-${var.environment}"

  tags = module.tags.tags
}

################################################################################
# EKS Managed Add-ons
################################################################################

module "eks_addons" {
  source = "git::https://github.com/venky1912/venky-terraform-module-eks-addons.git?ref=v0.1.1"

  cluster_name = module.eks.cluster_name

  addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    aws-ebs-csi-driver     = {}
    eks-pod-identity-agent = {}
  }

  tags = module.tags.tags
}
