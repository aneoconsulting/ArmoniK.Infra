output "id" {
  description = "The memorystore instance ID."
  value       = module.simple_memorystore.id
}

output "host" {
  description = "The IP address of the instance."
  value       = module.simple_memorystore.host
}

output "port" {
  description = "The port number of the exposed Redis endpoint."
  value       = module.simple_memorystore.port
}

output "read_endpoint" {
  description = " The IP address of the exposed readonly Redis endpoint."
  value       = module.simple_memorystore.read_endpoint
}

output "region" {
  description = "The region the instance lives in."
  value       = module.simple_memorystore.region
}

output "current_location_id" {
  description = "The current zone where the Redis endpoint is placed."
  value       = module.simple_memorystore.current_location_id
}

output "persistence_iam_identity" {
  description = "Cloud IAM identity used by import/export operations. Format is 'serviceAccount:'. May change over time"
  value       = module.simple_memorystore.persistence_iam_identity
}

output "auth_string" {
  description = "AUTH String set on the instance. This field will only be populated if auth_enabled is true."
  value       = module.simple_memorystore.auth_string
  sensitive   = true
}

output "server_ca_certs" {
  description = "List of server CA certificates for the instance"
  value       = module.simple_memorystore.server_ca_certs
  sensitive   = false
}
