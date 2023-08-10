output "auth_string" {
  description = "AUTH String set on the instance. This field will only be populated if auth_enabled is true."
  value       = google_redis_instance.cache.auth_string
  sensitive   = true
}

output "id" {
  description = "The Memorystore instance ID."
  value       = google_redis_instance.cache.id
}

output "current_location_id" {
  description = "The current zone where the Redis endpoint is placed."
  value       = google_redis_instance.cache.current_location_id
}

output "host" {
  description = "The IP address of the instance."
  value       = google_redis_instance.cache.host
}

output "port" {
  description = "The port number of the exposed Redis endpoint."
  value       = google_redis_instance.cache.port
}

output "persistence_iam_identity" {
  description = "Cloud IAM identity used by import/export operations. Format is 'serviceAccount:'. May change over time"
  value       = google_redis_instance.cache.persistence_iam_identity
}

output "server_ca_certs" {
  description = "List of server CA certificates for the instance"
  value       = google_redis_instance.cache.server_ca_certs
  sensitive   = true
}

output "nodes" {
  description = "Info per node"
  value       = google_redis_instance.cache.nodes
}

output "read_endpoint" {
  description = "The IP address of the exposed readonly Redis endpoint."
  value       = google_redis_instance.cache.read_endpoint
}

output "read_endpoint_port" {
  description = "The port number of the exposed readonly redis endpoint. Standard tier only. Write requests should target 'port'."
  value       = google_redis_instance.cache.read_endpoint_port
}

output "region" {
  description = "The region the instance lives in."
  value       = google_redis_instance.cache.region
}
