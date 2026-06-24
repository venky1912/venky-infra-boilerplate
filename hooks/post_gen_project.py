"""Post-generation hook: creates staging and prod environments from dev."""
import os
import shutil

PROJECT_SLUG = "{{ cookiecutter.project_slug }}"
VPC_CIDR_DEV = "{{ cookiecutter.vpc_cidr_dev }}"
VPC_CIDR_STAGING = "{{ cookiecutter.vpc_cidr_staging }}"
VPC_CIDR_PROD = "{{ cookiecutter.vpc_cidr_prod }}"
REGION = "{{ cookiecutter.aws_region }}"
DEPLOY_STAGING = "{{ cookiecutter.deploy_staging }}"
DEPLOY_PROD = "{{ cookiecutter.deploy_prod }}"

ENV_DIR = "environments"


def write_env_hcl(dst, target_env):
    env_hcl = os.path.join(dst, "env.hcl")
    lines = [
        "locals {",
        '  environment = "' + target_env + '"',
        '  region      = "' + REGION + '"',
        '  project     = "' + PROJECT_SLUG + '"',
        "}",
        "",
    ]
    with open(env_hcl, "w") as f:
        f.write(chr(10).join(lines))


def generate_env(target_env, vpc_cidr, single_nat):
    src = os.path.join(ENV_DIR, "dev")
    dst = os.path.join(ENV_DIR, target_env)

    if os.path.exists(dst):
        shutil.rmtree(dst)
    shutil.copytree(src, dst)

    for root, dirs, files in os.walk(dst):
        for fname in files:
            fpath = os.path.join(root, fname)
            with open(fpath, "r") as f:
                content = f.read()

            content = content.replace(PROJECT_SLUG + "-dev", PROJECT_SLUG + "-" + target_env)
            content = content.replace('environment = "dev"', 'environment = "' + target_env + '"')
            content = content.replace('Environment = "dev"', 'Environment = "' + target_env + '"')
            content = content.replace(VPC_CIDR_DEV, vpc_cidr)
            content = content.replace("single_nat_gateway = true", "single_nat_gateway = " + single_nat)

            with open(fpath, "w") as f:
                f.write(content)

    write_env_hcl(dst, target_env)


if DEPLOY_STAGING == "yes":
    generate_env("staging", VPC_CIDR_STAGING, "true")
    print("Generated: staging")
else:
    shutil.rmtree(os.path.join(ENV_DIR, "staging"), ignore_errors=True)
    print("Skipped: staging")

if DEPLOY_PROD == "yes":
    generate_env("prod", VPC_CIDR_PROD, "false")
    print("Generated: prod")
else:
    shutil.rmtree(os.path.join(ENV_DIR, "prod"), ignore_errors=True)
    print("Skipped: prod")

script = os.path.join("scripts", "create-backend.sh")
if os.path.exists(script):
    os.chmod(script, 0o755)

print("Infrastructure boilerplate ready: " + PROJECT_SLUG)
