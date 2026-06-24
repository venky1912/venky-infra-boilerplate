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

  # Uncomment for remote state
  # backend "s3" {
  #   bucket         = "{{ cookiecutter.project_slug }}-tfstate-{{ cookiecutter.environment }}"
  #   key            = "infra/terraform.tfstate"
  #   region         = "{{ cookiecutter.aws_region }}"
  #   dynamodb_table = "{{ cookiecutter.project_slug }}-tflock-{{ cookiecutter.environment }}"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = "{{ cookiecutter.aws_region }}"
}
