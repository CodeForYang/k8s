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

resource "random_password" "db" {
  length = 16
  special = true
}

resource "aws_ssm_parameter" "config" {
  for_each = var.db_config

  name = "/${var.env}/${var.project_name}/${each.key}"
  type = "String"
  value = each.value
  tags = local.all_tags
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

resource "aws_s3_bucket" "backup" {
  count = var.enable_backup ? 1 : 0

  bucket = "${var.project_name}-${var.env}-backup-${random_string.suffix.result}"
  tags = local.all_tags
}

resource "aws_s3_bucket_versioning" "backup" {
  count = var.enable_backup ? 1 : 0

  bucket = aws_s3_bucket.backup[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "db" {
  description = "KMS key for ${local.full_name} database encryption"
  deletion_window_in_days = 7
  tags = local.all_tags
  enable_key_rotation = true

  lifecycle {
    #⚠️ 重要：prevent_destroy 意味着 terraform destroy 会报错！练习完成后需要先注释掉这一行，apply 一次，然后才能 destroy。
    prevent_destroy = true
    ignore_changes = [ tags ]
  }
}

data "aws_ssm_parameter" "first_config" {
  name = aws_ssm_parameter.config[sort(keys(var.db_config))[0]].name
  depends_on = [ aws_ssm_parameter.config ]
}

data "aws_caller_identity" "current" {
  
}

data "aws_region" "current" {
  
}