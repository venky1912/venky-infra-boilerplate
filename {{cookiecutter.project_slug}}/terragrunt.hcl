# Root terragrunt.hcl — state, provider generation

locals {
  shared     = read_terragrunt_config("${get_parent_terragrunt_dir()}/shared.hcl")
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env        = local.env_config.locals.environment
  region     = local.shared.locals.region
  project    = local.shared.locals.project
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.region}"
    }
  EOF
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "${local.project}-tfstate-${local.env}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "${local.project}-tflock-${local.env}"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
