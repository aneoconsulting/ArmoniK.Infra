output "atlas_outputs" {
  description = "Map containing environment variables and secret references for ArmoniK components."
  value       = local.atlas_outputs
}

output "connection_string_secret_name" {
  description = "Name of the Kubernetes secret containing the Atlas connection string."
  value       = kubernetes_secret.mongodbatlas_connection_string.metadata[0].name
}

output "admin_secret_name" {
  description = "Name of the Kubernetes secret containing the Atlas admin credentials."
  value       = kubernetes_secret.mongodb_admin.metadata[0].name
}

output "generated_admin_user" {
  description = "The generated MongoDB admin username."
  value       = random_string.mongodb_admin_user.result
  sensitive   = true
}

output "generated_admin_password" {
  description = "The generated MongoDB admin password."
  value       = random_password.mongodb_admin_password.result
  sensitive   = true
}