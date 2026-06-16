
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

# ─────────────────────────────────────
# 1. 变量（Variable）—— 定义输入参数
# ─────────────────────────────────────

variable "project_name" {
  description = "项目名称"
  type = string
  default = "terraform-day3"
}

variable "environment" {
  description = "运行环境"
  type = string

  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "运行环境必须是 dev、staging 或 prod 之一。"
  }
}

variable "replicas" {
  description = "实例副本数"
  type = number
  default = 1
}

variable "enable_monitoring" {
  description = "是否启用监控"
  type = bool
  default = true
}

variable "tags" {
  description = "资源标签"
  type = map(string)
  default = {
    "Owner" = "terraform-learner"
  }
}

variable "availability_zones" {
  description = "可用区列表"
  type = list(string)
  default = [ "ap-norhteast-1a", "ap-norhteast-1c"]
}

variable "instance_config" {
  description = "实例配置"
  type = object({
    size = string
    disk = number
  })

  default = {
    size = "t3.micro"
    disk = 20
  }
}

# ─────────────────────────────────────
# 2. 本地值（Local）—— 计算中间值
# ─────────────────────────────────────
locals {

  full_name = "${var.project_name}-${var.environment}"

  log_level = var.environment == "prod" ? "warn" : "debug"

  replica_count = var.environment == "prod" ? var.replicas * 2 : var.replicas

  all_tags = merge(var.tags, {
    Name = local.full_name
    "Environment" = var.environment
    "Monitoring" = var.enable_monitoring ? "enabled" : "disabled"
  })

  formatted_zones = [for az in var.availability_zones : upper(az)]
}


# ─────────────────────────────────────
# 3. 资源（Resource）—— 创建资源
# ─────────────────────────────────────

resource "random_string" "suffix" {
  length = 8
  upper = false
  special = false
}

resource "local_file" "config" {
  content = <<-EOF
# ${local.full_name}  配置文件
project=${var.project_name}
env=${var.environment}
log_level=${local.log_level}
replicas=${local.replica_count}
instance_size=${var.instance_config.size}
disk_size=${var.instance_config.disk}
monitoring=${var.enable_monitoring}
zones=${join(", ", local.formatted_zones)}
suffix=${random_string.suffix.result}
EOF
  filename = "${path.module}/output/${local.full_name}-conf"
}

resource "local_file" "tags" {
  content  = jsonencode(local.all_tags)
  filename = "${path.module}/${local.full_name}-tags.json"
}

data "local_file" "config_content" {
  filename = local_file.config.filename
}

# ─────────────────────────────────────
# 5. 输出（Output）—— 暴露结果
# ─────────────────────────────────────
output "genereated_config" {
  value = local_file.config.filename
  description = "生成配置文件路径"
}

output "config_file_content" {
  value = local_file.config.content
  description = "配置文件内容"
}

output "final_tag" {
  value = local.all_tags
  description = "最终合并后的标签"
}

output "replica_count" {
  value = local.replica_count
  description = "根据环境计算的副本数"
}

output "formatted_availability_zones" {
  value = local.formatted_zones
  description = "大写格式化后的可用区列表"
}

output "db_connect_string" {
  value = "postgresql://admin:${random_string.suffix.result}@${local.full_name}.rds.amazonaws.com:5432/appdb"
  description = "数据库连接字符串"
  sensitive = true
}

# output "instance_ip" {
#   value = aws_instance.web.public_ip
#   description = "Web 服务器的公网 IP"
#   sensitive = false
# }
# variable "instance_type" {
#   description = "EC2实例规格"
#   type = string
#   default = "t3.micro"

#   validation {
#     condition = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
#     error_message = "实例类型必须是 t3.micro、t3.small 或 t3.medium 之一。"
#   }
# }
