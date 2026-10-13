terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "edward-s3-terraform-tfstate"
    key    = "staging/terraform.tfstate"
    region = "ap-northeast-1" 
    encrypt = true
    use_lockfile = true
  }
}