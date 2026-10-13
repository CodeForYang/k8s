# environments/staging/outputs.tf
# 执行 apply 后终端会显示这些值

output "alb_dns_name" {
  description = "ALB 的 DNS 域名"
  value       = module.app.alb_dns_name
}

output "instance_ids" {
  description = "EC2 实例 ID 列表"
  value       = module.app.instance_ids
}
