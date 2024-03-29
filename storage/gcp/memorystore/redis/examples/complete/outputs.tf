output "auth_string" {
  description = "AUTH String set on the instance. This field will only be populated if auth_enabled is true."
  value       = module.complete_memorystore_for_redis.auth_string
  sensitive   = true
}

output "id" {
  description = "The Memorystore instance ID."
  value       = module.complete_memorystore_for_redis.id
}

output "current_location_id" {
  description = "The current zone where the Redis endpoint is placed."
  value       = module.complete_memorystore_for_redis.current_location_id
}

output "host" {
  description = "The IP address of the instance."
  value       = module.complete_memorystore_for_redis.host
}

output "port" {
  description = "The port number of the exposed Redis endpoint."
  value       = module.complete_memorystore_for_redis.port
}

output "persistence_iam_identity" {
  description = "Cloud IAM identity used by import/export operations. Format is 'serviceAccount:'. May change over time"
  value       = module.complete_memorystore_for_redis.persistence_iam_identity
}

output "server_ca_certs" {
  description = "List of server CA certificates for the instance"
  value       = module.complete_memorystore_for_redis.server_ca_certs
  sensitive   = true
}

output "nodes" {
  description = "Info per node"
  value       = module.complete_memorystore_for_redis.nodes
}

output "read_endpoint" {
  description = "The IP address of the exposed readonly Redis endpoint."
  value       = module.complete_memorystore_for_redis.read_endpoint
}

output "read_endpoint_port" {
  description = "The port number of the exposed readonly redis endpoint. Standard tier only. Write requests should target 'port'."
  value       = module.complete_memorystore_for_redis.read_endpoint_port
}

output "region" {
  description = "The region the instance lives in."
  value       = module.complete_memorystore_for_redis.region
}
