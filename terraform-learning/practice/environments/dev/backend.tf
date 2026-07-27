terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "Edward-s3-terraform-state"
    key    = "terraform-learning/practice/environments/dev/terraform.tfstate"
    region = "ap-northeast-1" 
    encrypt = true
    use_lockfile = true
  }
}