output "rds_hostname" {
  description = "DNS do banco de dados"
  value       = aws_db_instance.shared_rds.address
}

output "redis_endpoint" {
  description = "Endereço do Redis"
  value       = aws_elasticache_cluster.api_redis.cache_nodes[0].address
}

output "s3_bucket_name" {
  value = aws_s3_bucket.video_storage.id
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region us-east-1 --name ${module.eks.cluster_name}"
}

output "rds_endpoint_final" {
  description = "Endpoint do banco de dados para a API"
  value       = aws_db_instance.shared_rds.endpoint
}