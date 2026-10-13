terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "~> 2.5"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}


module "config" {
  source = "../../modules/config-service"

  env = "prod"
  project_name = "config-service"
  replicas = 3
  app_config = {
    region = "ap-northeast-1"
    log_level = "debug"
    endpoint = "http://localhost:8080"
    cache_ttl = "300"
    auth_method = "iam"
  }
  feature_flags = [ "logging", "debug_mode" , "cache", "audit" ]
  tags = {
    Owner = "prod-team"
    Env = "prod"
  }
}