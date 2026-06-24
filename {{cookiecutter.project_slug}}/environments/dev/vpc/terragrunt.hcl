include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  shared = read_terragrunt_config("${get_parent_terragrunt_dir()}/../shared.hcl")
  env    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules/vpc"
}

inputs = {
  name               = "${local.shared.locals.project}-${local.env.locals.environment}"
  vpc_cidr           = local.env.locals.vpc_cidr
  availability_zones = ["${local.shared.locals.region}a", "${local.shared.locals.region}b", "${local.shared.locals.region}c"]

  public_subnet_cidrs   = [cidrsubnet(local.env.locals.vpc_cidr, 4, 0), cidrsubnet(local.env.locals.vpc_cidr, 4, 1), cidrsubnet(local.env.locals.vpc_cidr, 4, 2)]
  private_subnet_cidrs  = [cidrsubnet(local.env.locals.vpc_cidr, 4, 4), cidrsubnet(local.env.locals.vpc_cidr, 4, 5), cidrsubnet(local.env.locals.vpc_cidr, 4, 6)]
  database_subnet_cidrs = [cidrsubnet(local.env.locals.vpc_cidr, 4, 8), cidrsubnet(local.env.locals.vpc_cidr, 4, 9), cidrsubnet(local.env.locals.vpc_cidr, 4, 10)]

  enable_nat_gateway  = true
  single_nat_gateway  = local.env.locals.single_nat
  interface_endpoints = local.shared.locals.interface_endpoints

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                                                        = "1"
    "kubernetes.io/cluster/${local.shared.locals.project}-${local.env.locals.environment}" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb"                                                                  = "1"
    "kubernetes.io/cluster/${local.shared.locals.project}-${local.env.locals.environment}" = "shared"
  }

  tags = {
    Project     = local.shared.locals.project
    Environment = local.env.locals.environment
    Owner       = local.shared.locals.owner
    ManagedBy   = "terragrunt"
  }
}
