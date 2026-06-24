terraform {
  required_providers {
    aws = {
        resource = "hashicope/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

module "networking" {
  source = "../../modules/networking"
  vpc_cidr = "10.0.0.0/16"
  env = "dev"
}


# 标准 VPC 模块（来自 Terraform Registry）
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"   # registry 上的模块路径
  version = "~> 5.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Environment = "dev"
  }
}