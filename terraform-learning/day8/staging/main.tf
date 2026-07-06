module "networking" {
  source   = "../../modules/networking"
  vpc_cidr = "10.1.0.0/16"
  env      = "staging"
}

module "app" {
  source        = "../../modules/app"

  env           = "staging"
  instance_type = "t3.small"
  replicas      = 2

  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.subnet_ids
}