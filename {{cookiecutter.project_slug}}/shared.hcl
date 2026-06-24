# Common defaults shared across all environments
locals {
  project = "{{ cookiecutter.project_slug }}"
  owner   = "{{ cookiecutter.owner }}"
  region  = "{{ cookiecutter.aws_region }}"

  interface_endpoints = ["ec2", "ecr.api", "ecr.dkr", "sts", "logs", "elasticloadbalancing"]

  iam_roles = {
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

  kms_keys = {
    eks = { description = "EKS secrets encryption", enable_key_rotation = true }
  }
}
