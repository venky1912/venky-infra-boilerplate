# {{ cookiecutter.project_name }} - Infrastructure

## Structure

```
modules/          ← Terraform code (.tf)
  vpc/
  iam/
  security/
shared.hcl        ← Common defaults (all envs)
environments/     ← Terragrunt configs (per env)
  dev/env.hcl
  dev/vpc/terragrunt.hcl
  dev/iam/terragrunt.hcl
  dev/security/terragrunt.hcl
  staging/...
  prod/...
```

## Usage

```bash
./scripts/create-backend.sh dev
make plan ENV=dev
make apply ENV=dev
```

## Pipeline

| Trigger | Target |
|---------|--------|
| Any branch | dev |
| main | staging |
| Tag v* | prod |
