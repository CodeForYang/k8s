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

locals {
  # string 拼接
  full_name = "${var.project_name}-${var.env}"

  # 条件表达式（三目运算）
  log_level = var.env == "prod" ? "warn" : "debug"

  # 数字运算：prod 环境副本数翻倍
  effective_replicas = var.env == "prod" ? var.replicas * 2 : var.replicas

  # 合并 map
  all_tags = merge(var.tags, {
    Name        = local.full_name
    env = var.env
    Monitoring  = contains(var.feature_flags, "monitoring") ? "on" : "off"
    Backup     = var.enable_backup ? "enabled" : "disabled"
  })

  upper_flag = [for f in var.feature_flags : upper(f)]

}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# 为 app_config 的每个 key 生成一个配置文件
resource "local_file" "config" {
  for_each = var.app_config

  filename = "${local.full_name}-${each.key}.conf"
  content  = <<-EOT
    project   = ${var.project_name}
    env       = ${var.env}
    ${each.key} = ${each.value}
    replicas  = ${local.effective_replicas}
    backup    = ${var.enable_backup ? "enabled" : "disabled"}
    suffix    = ${random_string.suffix.result}
  EOT
}

# 汇总 JSON —— 所有配置信息聚合到一个文件
resource "local_file" "summary" {
  count = 1

  filename = "${local.full_name}-summary.json"
  content = jsonencode({
    project       = var.project_name
    env           = var.env
    log_level     = local.log_level
    replicas      = local.effective_replicas
    backup        = var.enable_backup
    suffix        = random_string.suffix.result
    feature_flags = var.feature_flags
    app_config    = var.app_config
    tags          = local.all_tags
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [content]
  }
}


data "local_file" "first_config" {

  filename = "${local.full_name}-${sort(keys(var.app_config))[0]}.conf"
  
}