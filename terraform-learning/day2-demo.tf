terraform {
   required_providers {
     random = {
        source = "hashicorp/random"
        version = "~> 3.6"
     }
   }
}



# 生成随机数
resource "random_string" "suffix" {
    length  = 6
    upper   = false
    special = false
}

resource "local_file" "config" {
    content = = <<-EOF
      server_name=web-${random_string.suffix.result}
      environment=${var.env}
      log_level=${local.log_level}
    EOF
    filename = "${path.module}/config-${random_string.suffix.result}.txt"
}

# 变量
variable "env" {
    type        = string
    default     = "dev"
}

# 本地变量
locals {
    log_level = var.env == "prod" ? "error" : "debug"
}

# 输出
output "created_file" {
  value = local_file.config.filename
  description = "刚刚创建的文件路径"
}