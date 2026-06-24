locals {
  environment    = "dev"
  vpc_cidr       = "{{ cookiecutter.vpc_cidr_dev }}"
  single_nat     = true
}
