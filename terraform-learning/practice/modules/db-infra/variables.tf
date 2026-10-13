variable "env" {
  description = "环境名称（dev / staging / prod），用于命名和标签隔离"
  type = string

  validation {
    condition = contains(["dev", "staging", "prod"], var.env)
    error_message = "环境类型必须是 dev/staing/prod 其中之一"
  }
}


variable "project_name" {
  description = "项目名称"
  type = string
  default = "aws-practice-edward"
}

variable "vpc_id" {
  description = "由 networking 模块的 output 传入"
  type = string
}

variable "replicas" {
  description = "EC2数量"
  type = number
  default = 1
}

variable "enable_backup" {
  description = "是否允许复制"
  type = bool
  default = true
}

variable "feature_flags" {
  description = "功能开关"
  type = list(string)
  default = ["logging", "monitoring"]
}

variable "db_config" {
  description = "数据库配置键值对（如 engine / version / instance_class / db_name）"
  type = map(string)
  default = {
    "engine" = "mysql"
    "version" = "8.0"
    "instance_class" = "db.t3.micro"
    "db_name" = "edward-s3-terraform-tfstate" 
  }

}
variable "app_config" {
  description = "环境特定的配置键值对"
  type = map(string)
}

variable "tags" {
  description = "资源标签"
  type = map(string)
  default = {
    "Owner" = "platform-team"
  }
}

variable "app_config" {
  description = "应用配置，键值对形式"
  type = map(string)
  default = {
    "size" = "t3.micro",
    "region" = "ap-northeast-1",
    "disk_size" = "20GB"
  }
}