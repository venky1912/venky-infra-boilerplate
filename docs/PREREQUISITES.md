# Prerequisites

## Required Tools

Install all required tools before using this boilerplate:

```bash
# macOS
brew install hashicorp/tap/terraform awscli kubectl git

# Verify versions
terraform --version   # >= 1.5.0
aws --version         # >= 2.x
kubectl version --client  # >= 1.28
git --version         # >= 2.x
```

## AWS Account Setup

### 1. Create State Backend

Run the helper script for each environment:

```bash
./scripts/create-backend.sh <environment> <region>
# e.g., ./scripts/create-backend.sh dev eu-west-1
```

This creates:
- S3 bucket: `<project>-tfstate-<env>` (versioned, encrypted)
- DynamoDB table: `<project>-tflock-<env>` (state locking)

### 2. AWS Authentication

Configure AWS credentials:

```bash
# Option A: Named profiles (recommended)
aws configure --profile dev
aws configure --profile staging
aws configure --profile prod

# Option B: Environment variables
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_REGION=eu-west-1
```

### 3. Required IAM Permissions

The deploying identity needs these permissions:
- `ec2:*` (VPC, subnets, security groups, NAT)
- `eks:*` (EKS cluster, node groups, add-ons)
- `iam:*` (roles, policies, OIDC providers)
- `kms:*` (KMS key creation)
- `logs:*` (CloudWatch log groups)
- `s3:*` (VPC endpoints, state bucket)
- `ssm:*` (hybrid node activation)
- `sqs:*` (Karpenter queue)
- `events:*` (EventBridge rules)

Or use `AdministratorAccess` for initial setup, then scope down.

## Network Planning

### CIDR Allocation Example

| Environment | VPC CIDR | Public | Private | Database |
|-------------|----------|--------|---------|----------|
| dev | 10.0.0.0/16 | 10.0.0.0/20 x3 | 10.0.64.0/20 x3 | 10.0.128.0/20 x3 |
| staging | 10.1.0.0/16 | 10.1.0.0/20 x3 | 10.1.64.0/20 x3 | 10.1.128.0/20 x3 |
| prod | 10.2.0.0/16 | 10.2.0.0/20 x3 | 10.2.64.0/20 x3 | 10.2.128.0/20 x3 |

### Hybrid Network Planning

If using hybrid nodes, ensure:
- Remote node CIDRs don't overlap with VPC CIDRs
- Remote pod CIDRs don't overlap with service CIDR (default 10.100.0.0/16)
- Direct Connect or VPN is established before deploying
