# venky-infra-boilerplate

Cruft/Cookiecutter template for generating production-ready EKS infrastructure (cloud + hybrid).

## Quick Start

```bash
pip install cruft
cruft create https://github.com/venky1912/venky-infra-boilerplate
```

## What Gets Generated

A complete Terraform project with:
- VPC (multi-AZ, NAT, VPC endpoints)
- IAM (cluster + node roles)
- KMS encryption + security groups (EKS ports pre-configured)
- EKS cluster (cloud or hybrid mode)
- Managed node groups
- EKS managed add-ons (CoreDNS, VPC CNI, kube-proxy, EBS CSI, Pod Identity)
- Hybrid node support (SSM activation, when enabled)
- State backend creation script
- Makefile for local dev

## Template Variables

| Variable | Default | Description |
|----------|---------|-------------|
| project_name | my-platform | Project name |
| environment | dev | Environment (dev/staging/prod) |
| owner | platform-team | Team owner |
| aws_region | eu-west-1 | AWS region |
| vpc_cidr | 10.0.0.0/16 | VPC CIDR |
| cluster_version | 1.30 | EKS K8s version |
| cluster_type | cloud | cloud or hybrid |
| node_instance_types | m5.large | Node instance type |
| node_min/max/desired | 2/10/3 | Autoscaling config |
| enable_hybrid | no | Enable hybrid node support |

## Update Existing Projects

```bash
cd my-platform
cruft update
```
