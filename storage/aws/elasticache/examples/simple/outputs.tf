output "endpoint_url" {
  description = "AWS Elastichache (Redis) endpoint url"
  value       = module.elasticache.endpoint_url
}

output "endpoint_host" {
  description = "AWS Elastichache (Redis) endpoint host"
  value       = module.elasticache.endpoint_host
}

output "endpoint_port" {
  description = "AWS Elastichache (Redis) endpoint port"
  value       = module.elasticache.endpoint_port
}

output "name" {
  description = "Name of Elasticache cluster"
  value       = module.elasticache.name
}

output "kms_key_id" {
  description = "ARN of KMS used for Elasticache"
  value       = module.elasticache.kms_key_id
}
