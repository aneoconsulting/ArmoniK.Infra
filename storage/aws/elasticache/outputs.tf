output "endpoint_url" {
  description = "AWS Elastichache (Redis) endpoint url"
  value       = "${aws_elasticache_replication_group.elasticache.primary_endpoint_address}:${aws_elasticache_replication_group.elasticache.port}"
}

output "endpoint_host" {
  description = "AWS Elastichache (Redis) endpoint host"
  value       = aws_elasticache_replication_group.elasticache.primary_endpoint_address
}

output "endpoint_port" {
  description = "AWS Elastichache (Redis) endpoint port"
  value       = aws_elasticache_replication_group.elasticache.port
}

output "name" {
  description = "Name of Elasticache cluster"
  value       = aws_elasticache_replication_group.elasticache.id
}

output "kms_key_id" {
  description = "ARN of KMS used for Elasticache"
  value       = aws_elasticache_replication_group.elasticache.kms_key_id
}
