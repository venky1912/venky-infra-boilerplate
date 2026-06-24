# venky-infra-boilerplate

Cruft/Cookiecutter template for generating base infrastructure (VPC, IAM, Security) with Terragrunt.

## Quick Start

```bash
pip install cruft
cruft create https://github.com/venky1912/venky-infra-boilerplate
```

## What Gets Generated

```
my-platform/
├── terragrunt.hcl              (root config: state, provider, versions)
├── environments/
│   ├── dev/
│   │   ├── env.hcl            (environment locals)
│   │   ├── vpc/terragrunt.hcl
│   │   ├── iam/terragrunt.hcl
│   │   └── security/terragrunt.hcl
│   ├── staging/  (auto-generated, skippable)
│   └── prod/     (auto-generated, skippable)
├── scripts/create-backend.sh
├── .github/workflows/infra.yml
├── Makefile
└── README.md
```

## Deploys

- VPC: Multi-AZ, subnets, NAT, VPC endpoints
- IAM: EKS cluster + node roles
- Security: KMS + security groups (EKS ports)

## Pipeline (Terragrunt)

| Trigger | Action |
|---------|--------|
| Any branch | Plan dev |
| Merge to main | Deploy staging |
| Tag v* | Deploy prod |

## After Infra

Deploy EKS cluster using [venky-eks-boilerplate](https://github.com/venky1912/venky-eks-boilerplate).
