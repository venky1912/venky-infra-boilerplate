################################################################################
# {{ cookiecutter.project_name }} - Dev Environment
################################################################################

module "tags" {
  source = "git::https://github.com/venky1912/venky-terraform-module-tags.git?ref=v0.1.0"

  project     = "{{ cookiecutter.project_name }}"
  environment = "dev"
  owner       = "{{ cookiecutter.owner }}"
  region      = "{{ cookiecutter.aws_region }}"
  criticality = "medium"
}

module "vpc" {
  source = "git::https://github.com/venky1912/venky-terraform-module-vpc.git?ref=v0.1.3"

  name               = "{{ cookiecutter.project_slug }}-dev"
  cidr_block         = "{{ cookiecutter.vpc_cidr_dev }}"
  availability_zones = ["{{ cookiecutter.aws_region }}a", "{{ cookiecutter.aws_region }}b", "{{ cookiecutter.aws_region }}c"]

  public_subnet_cidrs   = [cidrsubnet("{{ cookiecutter.vpc_cidr_dev }}", 4, 0), cidrsubnet("{{ cookiecutter.vpc_cidr_dev }}", 4, 1), cidrsubnet("{{ cookiecutter.vpc_cidr_dev }}", 4, 2)]
  private_subnet_cidrs  = [cidrsubnet("{{ cookiecutter.vpc_cidr_dev }}", 4, 4), cidrsubnet("{{ cookiecutter.vpc_cidr_dev }}", 4, 5), cidrsubnet("{{ cookiecutter.vpc_cidr_dev }}", 4, 6)]
  database_subnet_cidrs = [cidrsubnet("{{ cookiecutter.vpc_cidr_dev }}", 4, 8), cidrsubnet("{{ cookiecutter.vpc_cidr_dev }}", 4, 9), cidrsubnet("{{ cookiecutter.vpc_cidr_dev }}", 4, 10)]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  interface_endpoints      = ["ec2", "ecr.api", "ecr.dkr", "sts", "logs", "elasticloadbalancing"]

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                        = "1"
    "kubernetes.io/cluster/{{ cookiecutter.project_slug }}-dev" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb"                                  = "1"
    "kubernetes.io/cluster/{{ cookiecutter.project_slug }}-dev" = "shared"
  }

  tags = module.tags.tags
}

module "iam" {
  source = "git::https://github.com/venky1912/venky-terraform-module-iam.git?ref=v1.0.1"

  name = "{{ cookiecutter.project_slug }}-dev"

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

module "security" {
  source = "git::https://github.com/venky1912/venky-terraform-module-security.git?ref=v1.0.2"

  name = "{{ cookiecutter.project_slug }}-dev"

  kms_keys = {
    eks = { description = "EKS secrets encryption", enable_key_rotation = true }
  }

  security_groups = {
    eks-cluster = {
      vpc_id      = module.vpc.vpc_id
      description = "EKS cluster control plane"
      ingress_rules = {
        nodes-api = { description = "Nodes to API", from_port = 443, to_port = 443, ip_protocol = "tcp", cidr_ipv4 = "{{ cookiecutter.vpc_cidr_dev }}" }
      }
      egress_rules = {
        all = { description = "All egress", ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
      }
    }
    eks-node = {
      vpc_id      = module.vpc.vpc_id
      description = "EKS worker nodes"
      ingress_rules = {
        kubelet   = { description = "Cluster to nodes", from_port = 1025, to_port = 65535, ip_protocol = "tcp", cidr_ipv4 = "{{ cookiecutter.vpc_cidr_dev }}" }
        webhooks  = { description = "HTTPS webhooks", from_port = 443, to_port = 443, ip_protocol = "tcp", cidr_ipv4 = "{{ cookiecutter.vpc_cidr_dev }}" }
        node2node = { description = "Node to node", from_port = 0, to_port = 65535, ip_protocol = "-1", cidr_ipv4 = "{{ cookiecutter.vpc_cidr_dev }}" }
      }
      egress_rules = {
        all = { description = "All egress", ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
      }
    }
  }

  tags = module.tags.tags
}

module "eks" {
  source = "git::https://github.com/venky1912/venky-terraform-module-eks.git?ref=v0.2.1"

  name               = "{{ cookiecutter.project_slug }}-dev"
  cluster_version    = "{{ cookiecutter.cluster_version }}"
  cluster_role_arn   = module.iam.role_arns["eks-cluster"]
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security.security_group_ids["eks-cluster"]]

  cluster_type                         = "{{ cookiecutter.cluster_type }}"
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = {{ cookiecutter.cluster_endpoint_public_access }}
  cluster_encryption_kms_key_arn       = module.security.kms_key_arns["eks"]
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
      min_size       = {{ cookiecutter.node_min_size_dev }}
      max_size       = {{ cookiecutter.node_max_size_dev }}
      desired_size   = {{ cookiecutter.node_desired_size_dev }}
      disk_size      = 50
      labels         = { workload = "general", environment = "dev" }
    }
  }

  tags = module.tags.tags
}
{% if cookiecutter.enable_hybrid == 'yes' %}
module "hybrid_node_role" {
  count  = 1
  source = "git::https://github.com/venky1912/venky-terraform-module-eks.git//modules/hybrid-node-role?ref=v0.2.1"

  cluster_name = "{{ cookiecutter.project_slug }}-dev"
  tags         = module.tags.tags
}
{% endif %}
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
