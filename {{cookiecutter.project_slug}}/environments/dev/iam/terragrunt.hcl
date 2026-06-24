include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  shared = read_terragrunt_config("${get_parent_terragrunt_dir()}/../shared.hcl")
  env    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../modules/iam"
}

inputs = {
  name  = "${local.shared.locals.project}-${local.env.locals.environment}"
  roles = local.shared.locals.iam_roles

  tags = {
    Project     = local.shared.locals.project
    Environment = local.env.locals.environment
    Owner       = local.shared.locals.owner
    ManagedBy   = "terragrunt"
  }
}
