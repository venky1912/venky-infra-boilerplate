# {{ cookiecutter.project_name }} - Infrastructure

Base infrastructure (VPC, IAM, Security) managed with Terragrunt.

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Terraform | >= 1.5.0 | `brew install hashicorp/tap/terraform` |
| Terragrunt | >= 0.68 | `brew install terragrunt` |
| AWS CLI | >= 2.x | `brew install awscli` |

## Environments

| Env | VPC CIDR | Status |
|-----|----------|--------|
| dev | {{ cookiecutter.vpc_cidr_dev }} | ✅ |
{% if cookiecutter.deploy_staging == 'yes' %}| staging | {{ cookiecutter.vpc_cidr_staging }} | ✅ |{% endif %}
{% if cookiecutter.deploy_prod == 'yes' %}| prod | {{ cookiecutter.vpc_cidr_prod }} | ✅ |{% endif %}

## Usage

```bash
# Create state backend
./scripts/create-backend.sh dev

# Deploy dev infra
make plan ENV=dev
make apply ENV=dev

# Deploy staging
make plan ENV=staging
make apply ENV=staging
```

## Pipeline

| Trigger | Target Env |
|---------|-----------|
| PR to main | Plan only |
| Merge to main | Deploy staging |
| Tag v* | Deploy prod |
| Any branch push | Deploy dev |

## What's Deployed

- **VPC**: Multi-AZ, public/private/database subnets, NAT, VPC endpoints
- **IAM**: EKS cluster role, node role, instance profiles
- **Security**: KMS keys, EKS security groups (all required ports)
