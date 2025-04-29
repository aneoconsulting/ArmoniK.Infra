output "atlas_outputs" {
  description = "Atlas configuration outputs for ArmoniK"
  value       = local.atlas_outputs
}

output "connection_string" {
  description = "MongoDB Atlas connection string"
  value       = local.connection_string
  sensitive   = true
}

output "mongodb_url" {
  description = "MongoDB URL information"
  value       = local.mongodb_url
}

output "config" {
  description = "MongoDB configuration for ArmoniK"
  value       = local.atlas_outputs
}

output "endpoint_service_name" {
  description = "MongoDB Atlas privatelink endpoint service name"
  value       = mongodbatlas_privatelink_endpoint.pe.endpoint_service_name
}
