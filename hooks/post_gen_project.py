"""Post-generation hook: creates staging and prod environments from dev."""
import os
import shutil

PROJECT_SLUG = "{{ cookiecutter.project_slug }}"
VPC_CIDR_DEV = "{{ cookiecutter.vpc_cidr_dev }}"
VPC_CIDR_STAGING = "{{ cookiecutter.vpc_cidr_staging }}"
VPC_CIDR_PROD = "{{ cookiecutter.vpc_cidr_prod }}"
NODE_MIN_DEV = "{{ cookiecutter.node_min_size_dev }}"
NODE_MAX_DEV = "{{ cookiecutter.node_max_size_dev }}"
NODE_DESIRED_DEV = "{{ cookiecutter.node_desired_size_dev }}"
NODE_MIN_PROD = "{{ cookiecutter.node_min_size_prod }}"
NODE_MAX_PROD = "{{ cookiecutter.node_max_size_prod }}"
NODE_DESIRED_PROD = "{{ cookiecutter.node_desired_size_prod }}"

ENV_DIR = os.path.join("environments")


def generate_env(source_env, target_env, vpc_cidr, node_min, node_max, node_desired, single_nat):
    """Copy source env and adjust values for target env."""
    src = os.path.join(ENV_DIR, source_env)
    dst = os.path.join(ENV_DIR, target_env)

    if os.path.exists(dst):
        shutil.rmtree(dst)

    shutil.copytree(src, dst)

    for fname in os.listdir(dst):
        fpath = os.path.join(dst, fname)
        if not os.path.isfile(fpath):
            continue
        with open(fpath, "r") as f:
            content = f.read()

        # Replace env-specific values
        content = content.replace(f"-dev", f"-{target_env}")
        content = content.replace(f'environment = "dev"', f'environment = "{target_env}"')
        content = content.replace(f'environment = "dev"', f'environment = "{target_env}"')
        content = content.replace(VPC_CIDR_DEV, vpc_cidr)
        content = content.replace(f"tfstate-dev", f"tfstate-{target_env}")
        content = content.replace(f"tflock-dev", f"tflock-{target_env}")
        content = content.replace(f"single_nat_gateway = true", f"single_nat_gateway = {single_nat}")
        content = content.replace(f"min_size       = {NODE_MIN_DEV}", f"min_size       = {node_min}")
        content = content.replace(f"max_size       = {NODE_MAX_DEV}", f"max_size       = {node_max}")
        content = content.replace(f"desired_size   = {NODE_DESIRED_DEV}", f"desired_size   = {node_desired}")

        # Criticality
        if target_env == "prod":
            content = content.replace('criticality = "medium"', 'criticality = "critical"')

        with open(fpath, "w") as f:
            f.write(content)


# Generate staging (same node sizes as dev, different CIDR)
generate_env("dev", "staging", VPC_CIDR_STAGING, NODE_MIN_DEV, NODE_MAX_DEV, NODE_DESIRED_DEV, "true")

# Generate prod (bigger nodes, multi-NAT, different CIDR)
generate_env("dev", "prod", VPC_CIDR_PROD, NODE_MIN_PROD, NODE_MAX_PROD, NODE_DESIRED_PROD, "false")

print("✅ Generated environments: dev, staging, prod")
