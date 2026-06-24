"""Post-gen: creates staging/prod environments from dev with adjusted env.hcl."""
import os
import shutil

PROJECT_SLUG = "{{ cookiecutter.project_slug }}"
REGION = "{{ cookiecutter.aws_region }}"
VPC_CIDR_DEV = "{{ cookiecutter.vpc_cidr_dev }}"
VPC_CIDR_STAGING = "{{ cookiecutter.vpc_cidr_staging }}"
VPC_CIDR_PROD = "{{ cookiecutter.vpc_cidr_prod }}"
DEPLOY_STAGING = "{{ cookiecutter.deploy_staging }}"
DEPLOY_PROD = "{{ cookiecutter.deploy_prod }}"

ENV_DIR = "environments"


def write_env_hcl(dst, env, vpc_cidr, single_nat):
    lines = [
        "locals {",
        '  environment    = "' + env + '"',
        '  vpc_cidr       = "' + vpc_cidr + '"',
        "  single_nat     = " + single_nat,
        "}",
        "",
    ]
    with open(os.path.join(dst, "env.hcl"), "w") as f:
        f.write(chr(10).join(lines))


def generate_env(target_env, vpc_cidr, single_nat):
    src = os.path.join(ENV_DIR, "dev")
    dst = os.path.join(ENV_DIR, target_env)
    if os.path.exists(dst):
        shutil.rmtree(dst)
    shutil.copytree(src, dst)
    write_env_hcl(dst, target_env, vpc_cidr, single_nat)


if DEPLOY_STAGING == "yes":
    generate_env("staging", VPC_CIDR_STAGING, "true")
    print("Generated: staging")
else:
    print("Skipped: staging")

if DEPLOY_PROD == "yes":
    generate_env("prod", VPC_CIDR_PROD, "false")
    print("Generated: prod")
else:
    print("Skipped: prod")

script = os.path.join("scripts", "create-backend.sh")
if os.path.exists(script):
    os.chmod(script, 0o755)

print("Ready: " + PROJECT_SLUG)
