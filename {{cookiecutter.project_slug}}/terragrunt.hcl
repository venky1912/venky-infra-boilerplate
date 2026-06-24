# Root terragrunt.hcl
# Common config inherited by all environments

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals.environment
  region   = local.env_vars.locals.region
  project  = local.env_vars.locals.project
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

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.5.0"
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = ">= 5.0, < 7.0"
        }
      }
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

inputs = {
  project     = local.project
  environment = local.env
  region      = local.region
}
