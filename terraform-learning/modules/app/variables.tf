# modules/app/variables.tf
# 定义这个模块需要外部传入哪些参数

variable "env" {
  description = "环境名称（dev / staging / prod），用于命名和标签隔离"
  type        = string
}

variable "instance_type" {
  description = "EC2 实例规格，不同环境可以用不同规格"
  type        = string
}

variable "replicas" {
  description = "EC2 实例数量，生产环境通常比开发环境多"
  type        = number
}

variable "vpc_id" {
  description = "目标 VPC ID，由调用方传入（引用 networking 模块的输出）"
  type        = string
}

variable "public_subnet_ids" {
  description = "公有子网 ID 列表，用于挂载 ALB 和 EC2"
  type        = list(string)
}