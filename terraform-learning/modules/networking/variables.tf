variable "vpc_cidr" {
  description = "VPC 的 CIDR 地址段，如 10.0.0.0/16"
  type        = string
}

variable "env" {
  description = "环境名称（dev / staging / prod），用于资源命名和标签隔离"
  type        = string
}