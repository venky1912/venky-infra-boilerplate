include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/venky1912/venky-terraform-module-iam.git?ref=v1.0.1"
}

inputs = {
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

  tags = {
    Project     = "{{ cookiecutter.project_name }}"
    Environment = "dev"
    Owner       = "{{ cookiecutter.owner }}"
    ManagedBy   = "terragrunt"
  }
}
