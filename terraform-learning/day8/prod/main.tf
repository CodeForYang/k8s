module "networking" {
  source   = "../../modules/networking"
  vpc_cidr = "10.2.0.0/16"
  env      = "prod"
}

module "app" {
  source        = "../../modules/app"

  env           = "prod"
  instance_type = "t3.large"
  replicas      = 5

  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.subnet_ids
}