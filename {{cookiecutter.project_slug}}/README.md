# {{ cookiecutter.project_name }}

Infrastructure for **{{ cookiecutter.project_name }}** managed by Terraform.

## Environments

| Environment | VPC CIDR | NAT | Nodes |
|-------------|----------|-----|-------|
| dev | {{ cookiecutter.vpc_cidr_dev }} | Single | {{ cookiecutter.node_min_size_dev }}-{{ cookiecutter.node_max_size_dev }} |
| staging | {{ cookiecutter.vpc_cidr_staging }} | Single | {{ cookiecutter.node_min_size_dev }}-{{ cookiecutter.node_max_size_dev }} |
| prod | {{ cookiecutter.vpc_cidr_prod }} | Multi-AZ | {{ cookiecutter.node_min_size_prod }}-{{ cookiecutter.node_max_size_prod }} |

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI >= 2.x
- kubectl >= 1.28

## Quick Start

```bash
# Create state backend
./scripts/create-backend.sh dev
./scripts/create-backend.sh staging
./scripts/create-backend.sh prod

# Deploy dev
make init ENV=dev
make plan ENV=dev
make apply ENV=dev

# Connect
aws eks update-kubeconfig --region {{ cookiecutter.aws_region }} --name {{ cookiecutter.project_slug }}-dev
kubectl get nodes
```

## Update from Template

```bash
cruft update
```
