locals {

  # Possible Availability Zones and public/private CIDRs.
  vpc_cidr                  = "10.0.0.0/16"
  available_AZs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  available_public_subnets  = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
  available_private_subnets = ["10.0.64.0/20", "10.0.80.0/20", "10.0.96.0/20"]

  #Logic that determines which AZs and public/private CIDRs are actually used.
  availability_zones = slice(local.available_AZs, 0, var.az_count)
  public_subnets     = slice(local.available_public_subnets, 0, var.az_count)
  private_subnets    = slice(local.available_private_subnets, 0, var.az_count)

}

module "portfolio" {
  source = "../tf_portfolio_module"
  env    = var.env
  region = var.region

  vpc_cidr           = local.vpc_cidr
  availability_zones = local.availability_zones
  public_subnets     = local.public_subnets
  private_subnets    = local.private_subnets
}
