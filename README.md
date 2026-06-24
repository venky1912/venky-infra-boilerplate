# venky-infra-boilerplate

Production-ready infrastructure boilerplate for deploying EKS cloud and hybrid clusters.

## Architecture

```
                    ┌──────────────────────────────────────┐
                    │        AWS Account (per env)         │
                    ├──────────────────────────────────────┤
                    │  ┌─────────────────────────────────┐ │
                    │  │            VPC                   │ │
                    │  │  Public / Private / Database     │ │
                    │  │  NAT GW | IGW | VPC Endpoints   │ │
                    │  └─────────────────────────────────┘ │
                    │  ┌─────────────────────────────────┐ │
                    │  │         EKS Cluster              │ │
                    │  │  Cloud or Hybrid mode            │ │
                    │  │  Managed Node Groups             │ │
                    │  │  KMS Encryption | Flow Logs      │ │
                    │  └─────────────────────────────────┘ │
                    │  ┌─────────────────────────────────┐ │
                    │  │    IAM | Security | Networking   │ │
                    │  │  OIDC | SGs | KMS | Route53     │ │
                    │  └─────────────────────────────────┘ │
                    └──────────────────────────────────────┘
```

## Prerequisites

Before using this boilerplate, ensure you have:

### Tools Required

| Tool | Version | Installation |
|------|---------|-------------|
| Terraform | >= 1.5.0 | `brew install hashicorp/tap/terraform` |
| AWS CLI | >= 2.x | `brew install awscli` |
| kubectl | >= 1.28 | `brew install kubectl` |
| git | >= 2.x | `brew install git` |

### AWS Requirements

- AWS account(s) with appropriate permissions
- IAM user or role with admin access (for initial setup)
- S3 bucket for Terraform state (`<project>-tfstate-<env>`)
- DynamoDB table for state locking (`<project>-tflock-<env>`)
- AWS CLI configured: `aws configure --profile <env>`

### Networking Prerequisites

- Decide on VPC CIDR ranges (non-overlapping across environments)
- Identify required availability zones (minimum 2, recommended 3)
- For hybrid: on-prem network CIDRs for remote node/pod networks

## Quick Start

```bash
# 1. Clone and configure
git clone https://github.com/venky1912/venky-infra-boilerplate.git
cd venky-infra-boilerplate
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
# Edit terraform.tfvars with your values

# 2. Create state backend (one-time)
cd scripts && ./create-backend.sh dev

# 3. Deploy
cd ../environments/dev
terraform init
terraform plan
terraform apply
```

## Environments

| Environment | Purpose | HA Level |
|-------------|---------|----------|
| `dev` | Development and testing | Single NAT, smaller nodes |
| `staging` | Pre-production validation | Single NAT, prod-like config |
| `prod` | Production workloads | Multi-AZ NAT, HA everything |

## Configuration

All configuration is done via `terraform.tfvars` in each environment directory.

### Key Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `project_name` | Project identifier | `my-platform` |
| `environment` | Environment name | `dev` |
| `region` | AWS region | `eu-west-1` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `cluster_version` | EKS K8s version | `1.30` |
| `cluster_type` | `cloud` or `hybrid` | `cloud` |
| `node_instance_types` | EC2 instance types | `["m5.large"]` |
| `node_min_size` | Minimum nodes | `2` |
| `node_max_size` | Maximum nodes | `20` |

### Security Group Ports (EKS)

The boilerplate pre-configures required EKS ports:

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 443 | TCP | Nodes → Cluster | API server |
| 1025-65535 | TCP | Cluster → Nodes | Kubelet, apps |
| 443 | TCP | Cluster → Nodes | Webhook callbacks |
| All | All | Nodes → Nodes | Pod-to-pod |

## Pipeline Stages

### CI Pipeline (on Pull Request)

```
Stage 1: Validate PR Title (conventional commits)
    ↓
Stage 2: Security Scan (Trivy + Checkov)
    ↓
Stage 3: TFLint
    ↓
Stage 4: Terraform Format
    ↓
Stage 5: Terraform Validate
    ↓
Stage 6: Terraform Plan (per environment)
    ↓
Stage 7: Cost Estimation
    ↓
✅ CI Passed
```

### CD Pipeline (on Merge to main)

```
Stage 1: Terraform Plan (target environment)
    ↓
Stage 2: Manual Approval (prod only)
    ↓
Stage 3: Terraform Apply
    ↓
Stage 4: Smoke Test (cluster connectivity)
    ↓
✅ Deployment Complete
```

## Modules Used

| Module | Version | Purpose |
|--------|---------|---------|
| [venky-terraform-module-tags](https://github.com/venky1912/venky-terraform-module-tags) | v0.1.0 | Consistent tagging |
| [venky-terraform-module-vpc](https://github.com/venky1912/venky-terraform-module-vpc) | v0.1.3 | Multi-AZ VPC |
| [venky-terraform-module-iam](https://github.com/venky1912/venky-terraform-module-iam) | v1.0.1 | IAM roles & policies |
| [venky-terraform-module-security](https://github.com/venky1912/venky-terraform-module-security) | v1.0.1 | KMS & security groups |
| [venky-terraform-module-eks](https://github.com/venky1912/venky-terraform-module-eks) | v0.2.1 | EKS cluster |
| [venky-terraform-module-eks-addons](https://github.com/venky1912/venky-terraform-module-eks-addons) | v0.1.1 | EKS managed add-ons |

## Hybrid Cluster Support

To deploy a hybrid cluster with on-prem nodes:

1. Set `cluster_type = "hybrid"` in `terraform.tfvars`
2. Configure `remote_node_cidrs` and `remote_pod_cidrs`
3. After apply, retrieve SSM activation credentials from outputs
4. Install `nodeadm` on on-prem nodes and register them

See [docs/HYBRID.md](docs/HYBRID.md) for full instructions.

## Contributing

1. Create a feature branch: `git checkout -b feat/my-change`
2. Make changes and commit: `git commit -m "feat: add something"`
3. Push and create PR: `gh pr create`
4. CI validates automatically
5. On merge: release-please bumps version

## Licence

MIT
