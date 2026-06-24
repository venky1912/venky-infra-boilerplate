include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  shared = read_terragrunt_config("${get_parent_terragrunt_dir()}/../shared.hcl")
  env    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules/security"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  name     = "${local.shared.locals.project}-${local.env.locals.environment}"
  kms_keys = local.shared.locals.kms_keys

  security_groups = {
    eks-cluster = {
      vpc_id      = dependency.vpc.outputs.vpc_id
      description = "EKS cluster control plane"
      ingress_rules = {
        nodes-api = { description = "Nodes to API", from_port = 443, to_port = 443, ip_protocol = "tcp", cidr_ipv4 = local.env.locals.vpc_cidr }
      }
      egress_rules = {
        all = { description = "All egress", ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
      }
    }
    eks-node = {
      vpc_id      = dependency.vpc.outputs.vpc_id
      description = "EKS worker nodes"
      ingress_rules = {
        kubelet   = { description = "Cluster to nodes", from_port = 1025, to_port = 65535, ip_protocol = "tcp", cidr_ipv4 = local.env.locals.vpc_cidr }
        webhooks  = { description = "HTTPS webhooks", from_port = 443, to_port = 443, ip_protocol = "tcp", cidr_ipv4 = local.env.locals.vpc_cidr }
        node2node = { description = "Node to node", from_port = 0, to_port = 65535, ip_protocol = "-1", cidr_ipv4 = local.env.locals.vpc_cidr }
      }
      egress_rules = {
        all = { description = "All egress", ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
      }
    }
  }

  tags = {
    Project     = local.shared.locals.project
    Environment = local.env.locals.environment
    Owner       = local.shared.locals.owner
    ManagedBy   = "terragrunt"
  }
}
