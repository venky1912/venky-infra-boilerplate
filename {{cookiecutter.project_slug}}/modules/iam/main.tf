module "iam" {
  source = "git::https://github.com/venky1912/venky-terraform-module-iam.git?ref=v1.0.1"

  name = var.name
  roles = var.roles
  tags  = var.tags
}
