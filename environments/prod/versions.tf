terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0, < 6.0"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "my-platform-tfstate-prod"
  #   key            = "infra/prod/terraform.tfstate"
  #   region         = "eu-west-1"
  #   dynamodb_table = "my-platform-tflock-prod"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = module.tags.tags
  }
}
