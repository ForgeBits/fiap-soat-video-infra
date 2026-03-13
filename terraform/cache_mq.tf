# Redis para a API (ElastiCache)
resource "aws_elasticache_cluster" "api_redis" {
  cluster_id           = "api-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"

  subnet_group_name = aws_elasticache_subnet_group.redis_net.name
  security_group_ids = [aws_security_group.fiapx_sg.id]
}