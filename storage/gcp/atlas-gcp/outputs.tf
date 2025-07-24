output "connection_string" {
  description = "The MongoDB connection string"
  value       = data.mongodbatlas_advanced_cluster.atlas.connection_strings[0].private_endpoint[0].srv_connection_string
  sensitive   = true
}

output "connection_strings" {
  description = "All MongoDB connection strings"
  value       = data.mongodbatlas_advanced_cluster.atlas.connection_strings
  sensitive   = true
}
