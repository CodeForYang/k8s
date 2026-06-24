output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "web_server_ip" {
  description = "Web 服务器公网 IP"
  value       = aws_instance.web.public_ip
}

output "db_endpoint" {
  description = "数据库连接地址"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "web_server_url" {
  value = "http://${aws_instance.web.public_ip}"
}