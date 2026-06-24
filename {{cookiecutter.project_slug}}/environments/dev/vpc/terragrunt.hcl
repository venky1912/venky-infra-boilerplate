include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/venky1912/venky-terraform-module-vpc.git?ref=v0.1.3"
}

inputs = {
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
    "kubernetes.io/role/internal-elb"                            = "1"
    "kubernetes.io/cluster/{{ cookiecutter.project_slug }}-dev" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb"                                     = "1"
    "kubernetes.io/cluster/{{ cookiecutter.project_slug }}-dev" = "shared"
  }

  tags = {
    Project     = "{{ cookiecutter.project_name }}"
    Environment = "dev"
    Owner       = "{{ cookiecutter.owner }}"
    ManagedBy   = "terragrunt"
  }
}
