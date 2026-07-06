output "vpc_id" {
  description = "VPC ID，供 app 模块引用"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "公有子网 ID 列表，供 app 模块挂载 ALB 和 EC2"
  value       = aws_subnet.public[*].id
}