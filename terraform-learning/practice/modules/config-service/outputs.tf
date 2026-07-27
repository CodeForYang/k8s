
output "config_files" {
  description = "生成的 config 文件路径列表"
  value = [for f in local_file.config : f.filename]
}

output "summary_file" {
  description = "汇总文件路径"
  value = local_file.summary[0].filename
}

output "sample_config_content" {
  description = "数据源读取到的配置文件内容"
  value = data.local_file.first_config.filename
}

output "connection_string" {
  description = "模拟的数据库连接串"
  sensitive = true
  value = "postgres://${local.full_name}:${random_string.suffix.result}@db.example.com:5432/mydb"
}

output "all_tags" {
  description = "最终合并后的完整标签"
  value = local.all_tags
}