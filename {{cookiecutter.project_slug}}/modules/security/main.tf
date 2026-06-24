module "security" {
  source = "git::https://github.com/venky1912/venky-terraform-module-security.git?ref=v1.0.2"

  name            = var.name
  kms_keys        = var.kms_keys
  security_groups = var.security_groups
  tags            = var.tags
}
