# {{ cookiecutter.project_name }} - Infrastructure

Infrastructure for **{{ cookiecutter.project_name }}** ({{ cookiecutter.environment }}) in `{{ cookiecutter.aws_region }}`.

## Configuration

| Setting | Value |
|---------|-------|
| Project | {{ cookiecutter.project_name }} |
| Environment | {{ cookiecutter.environment }} |
| Region | {{ cookiecutter.aws_region }} |
| VPC CIDR | {{ cookiecutter.vpc_cidr }} |
| Cluster Type | {{ cookiecutter.cluster_type }} |
| Cluster Version | {{ cookiecutter.cluster_version }} |
| Node Types | {{ cookiecutter.node_instance_types }} |
| Nodes | {{ cookiecutter.node_min_size }}-{{ cookiecutter.node_max_size }} (desired: {{ cookiecutter.node_desired_size }}) |

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI >= 2.x configured
- kubectl >= 1.28
- S3 bucket + DynamoDB table for state (see scripts/create-backend.sh)

## Usage

```bash
# Initialise
make init

# Plan
make plan

# Apply
make apply

# Connect to cluster
$(terraform output -raw kubeconfig_command)
kubectl get nodes
```

## Modules

| Module | Version |
|--------|---------|
| venky-terraform-module-tags | v0.1.0 |
| venky-terraform-module-vpc | v0.1.3 |
| venky-terraform-module-iam | v1.0.1 |
| venky-terraform-module-security | v1.0.2 |
| venky-terraform-module-eks | v0.2.1 |
| venky-terraform-module-eks-addons | v0.1.1 |

## Update from Template

```bash
cruft update
```
