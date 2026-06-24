variable "region" {
  description = "AWS 区域"
  type = string
  default = "ap-northeast-1"
}

variable "project" {
  description = "项目名称"
  type = string
  default = "terraform-demo"
}

variable "env" {
  description = "环境名称"
  type = string
  default = "dev"
}

variable "db_password" {
  description = "数据库密码"
  type = string
  sensitive = true
}


    