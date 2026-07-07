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

output "alb_dns_name" {
  description = "ALB 的 DNS 域名"
  value       = module.app.alb_dns_name
}

output "instance_ids" {
  description = "EC2 实例 ID 列表"
  value       = module.app.instance_ids
}