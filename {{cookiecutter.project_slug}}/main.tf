################################################################################
# Tags
################################################################################

module "tags" {
  source = "git::https://github.com/venky1912/venky-terraform-module-tags.git?ref=v0.1.0"

  project     = "{{ cookiecutter.project_name }}"
  environment = "{{ cookiecutter.environment }}"
  owner       = "{{ cookiecutter.owner }}"
  region      = "{{ cookiecutter.aws_region }}"
  criticality = "{{ cookiecutter.environment }}" == "prod" ? "critical" : "medium"
}

################################################################################
# VPC
################################################################################

module "vpc" {
  source = "git::https://github.com/venky1912/venky-terraform-module-vpc.git?ref=v0.1.3"

  name               = "{{ cookiecutter.project_slug }}-{{ cookiecutter.environment }}"
  cidr_block         = "{{ cookiecutter.vpc_cidr }}"
  availability_zones = ["{{ cookiecutter.aws_region }}a", "{{ cookiecutter.aws_region }}b", "{{ cookiecutter.aws_region }}c"]

  public_subnet_cidrs   = [{% for cidr in cookiecutter.public_subnet_cidrs.split(',') %}"{{ cidr | trim }}"{% if not loop.last %}, {% endif %}{% endfor %}]
  private_subnet_cidrs  = [{% for cidr in cookiecutter.private_subnet_cidrs.split(',') %}"{{ cidr | trim }}"{% if not loop.last %}, {% endif %}{% endfor %}]
  database_subnet_cidrs = [{% for cidr in cookiecutter.database_subnet_cidrs.split(',') %}"{{ cidr | trim }}"{% if not loop.last %}, {% endif %}{% endfor %}]

  enable_nat_gateway = true
  single_nat_gateway = {{ cookiecutter.single_nat_gateway }}

  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  interface_endpoints      = ["ec2", "ecr.api", "ecr.dkr", "sts", "logs", "elasticloadbalancing"]

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                                              = "1"
    "kubernetes.io/cluster/{{ cookiecutter.project_slug }}-{{ cookiecutter.environment }}" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb"                                                        = "1"
    "kubernetes.io/cluster/{{ cookiecutter.project_slug }}-{{ cookiecutter.environment }}" = "shared"
  }

  tags = module.tags.tags
}

################################################################################
# IAM
################################################################################

module "iam" {
  source = "git::https://github.com/venky1912/venky-terraform-module-iam.git?ref=v1.0.1"

  name = "{{ cookiecutter.project_slug }}-{{ cookiecutter.environment }}"

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
  source = "git::https://github.com/venky1912/venky-terraform-module-security.git?ref=v1.0.2"

  name = "{{ cookiecutter.project_slug }}-{{ cookiecutter.environment }}"

  kms_keys = {
    eks = {
      description         = "EKS secrets encryption"
      enable_key_rotation = true
    }
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
          cidr_ipv4   = "{{ cookiecutter.vpc_cidr }}"
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
          cidr_ipv4   = "{{ cookiecutter.vpc_cidr }}"
        }
        cluster-to-nodes-https = {
          description = "Cluster to nodes HTTPS (webhooks)"
          from_port   = 443
          to_port     = 443
          ip_protocol = "tcp"
          cidr_ipv4   = "{{ cookiecutter.vpc_cidr }}"
        }
        node-to-node = {
          description = "Node to node communication"
          from_port   = 0
          to_port     = 65535
          ip_protocol = "-1"
          cidr_ipv4   = "{{ cookiecutter.vpc_cidr }}"
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

  name             = "{{ cookiecutter.project_slug }}-{{ cookiecutter.environment }}"
  cluster_version  = "{{ cookiecutter.cluster_version }}"
  cluster_role_arn = module.iam.role_arns["eks-cluster"]
  subnet_ids       = module.vpc.private_subnet_ids
  security_group_ids = [module.security.security_group_ids["eks-cluster"]]

  cluster_type                    = "{{ cookiecutter.cluster_type }}"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = {{ cookiecutter.cluster_endpoint_public_access }}

  cluster_encryption_kms_key_arn = module.security.kms_key_arns["eks"]
{% if cookiecutter.enable_hybrid == 'yes' %}
  remote_network_config = {
    remote_node_cidrs = ["{{ cookiecutter.remote_node_cidrs }}"]
    remote_pod_cidrs  = ["{{ cookiecutter.remote_pod_cidrs }}"]
  }

  hybrid_node_role_arn = module.hybrid_node_role[0].role_arn
{% else %}
  remote_network_config = null
  hybrid_node_role_arn  = null
{% endif %}
  managed_node_groups = {
    general = {
      node_role_arn  = module.iam.role_arns["eks-node"]
      instance_types = ["{{ cookiecutter.node_instance_types }}"]
      min_size       = {{ cookiecutter.node_min_size }}
      max_size       = {{ cookiecutter.node_max_size }}
      desired_size   = {{ cookiecutter.node_desired_size }}
      disk_size      = 50
      labels         = { workload = "general", environment = "{{ cookiecutter.environment }}" }
    }
  }

  tags = module.tags.tags
}
{% if cookiecutter.enable_hybrid == 'yes' %}
################################################################################
# Hybrid Node Role
################################################################################

module "hybrid_node_role" {
  count  = 1
  source = "git::https://github.com/venky1912/venky-terraform-module-eks.git//modules/hybrid-node-role?ref=v0.2.1"

  cluster_name = "{{ cookiecutter.project_slug }}-{{ cookiecutter.environment }}"

  tags = module.tags.tags
}
{% endif %}
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
