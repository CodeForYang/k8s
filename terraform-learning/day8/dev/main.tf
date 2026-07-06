module "networking" {
  source   = "../../modules/networking"
  vpc_cidr = "10.0.0.0/16"
  env      = "dev"
}

module "app" {
  source        = "../../modules/app"

  env           = "dev"
  instance_type = "t3.micro"
  replicas      = 1

  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.subnet_ids
}