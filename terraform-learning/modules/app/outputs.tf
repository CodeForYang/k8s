# modules/app/outputs.tf
# 暴露给调用方使用的输出值

output "alb_dns_name" {
  description = "ALB 的 DNS 域名，访问这个域名就能到达应用"
  value       = aws_lb.app.dns_name
}

output "instance_ids" {
  description = "创建的 EC2 实例 ID 列表"
  value       = aws_instance.web[*].id
}

output "security_group_id" {
  description = "Web 安全组 ID"
  value       = aws_security_group.web.id
}