output "host" {
  description = "MongoDB Atlas host"
  value       = local.mongodb_url.dns
}

output "url" {
  description = "MongoDB Atlas connection URL"
  value       = try(data.mongodbatlas_advanced_cluster.aklocal.connection_strings[0].standard_srv, "")
}

output "env" {
  description = "Environment variables for MongoDB Atlas configuration"
  value       = local.atlas_outputs.env
}

output "env_from_secret" {
  description = "Environment variables from secrets for MongoDB Atlas configuration"
  value       = local.atlas_outputs.env_from_secret
}

output "user_credentials" {
  description = "User credentials of MongoDB Atlas"
  value = {
    secret    = kubernetes_secret.mongodb_admin.metadata[0].name
    data_keys = keys(kubernetes_secret.mongodb_admin.data)
  }
}

output "url" {
  description = "MongoDB Atlas connection URL"
  value       = local.public_connection_string
}

output "connection_string" {
  description = "MongoDB Atlas connection string"
  value       = local.public_connection_string
  sensitive   = true
}


output "private_link_id" {
  description = "MongoDB Atlas private link ID (if private endpoint is enabled)"
  value       = var.enable_private_endpoint ? mongodbatlas_privatelink_endpoint.pe[0].id : null
}

output "private_endpoint_service_name" {
  description = "MongoDB Atlas private endpoint service name (if private endpoint is enabled)"
  value       = var.enable_private_endpoint && var.aws_endpoint_id != "" ? mongodbatlas_privatelink_endpoint_service.pe_service[0].endpoint_service_id : null
}