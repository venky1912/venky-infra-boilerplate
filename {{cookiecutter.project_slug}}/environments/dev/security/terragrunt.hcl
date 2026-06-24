include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
}

terraform {
  source = "git::https://github.com/venky1912/venky-terraform-module-security.git?ref=v1.0.2"
}

inputs = {
  name = "{{ cookiecutter.project_slug }}-dev"

  kms_keys = {
    eks = { description = "EKS secrets encryption", enable_key_rotation = true }
  }

  security_groups = {
    eks-cluster = {
      vpc_id      = dependency.vpc.outputs.vpc_id
      description = "EKS cluster control plane"
      ingress_rules = {
        nodes-api = { description = "Nodes to API", from_port = 443, to_port = 443, ip_protocol = "tcp", cidr_ipv4 = "{{ cookiecutter.vpc_cidr_dev }}" }
      }
      egress_rules = {
        all = { description = "All egress", ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
      }
    }
    eks-node = {
      vpc_id      = dependency.vpc.outputs.vpc_id
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

  tags = {
    Project     = "{{ cookiecutter.project_name }}"
    Environment = "dev"
    Owner       = "{{ cookiecutter.owner }}"
    ManagedBy   = "terragrunt"
  }
}
