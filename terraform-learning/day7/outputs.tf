output "cluster_name" {
  description = "EKS 集群名称"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API Server 地址"
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "配置 kubectl 的命令"
  value       = "aws eks update-kubeconfig --region ap-northeast-1 --name ${module.eks.cluster_name}"
}