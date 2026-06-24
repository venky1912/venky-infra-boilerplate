module "vpc" {
  source = "git::https://github.com/venky1912/venky-terraform-module-vpc.git?ref=v0.1.3"

  name               = var.name
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  interface_endpoints      = var.interface_endpoints

  private_subnet_tags = var.private_subnet_tags
  public_subnet_tags  = var.public_subnet_tags

  tags = var.tags
}
