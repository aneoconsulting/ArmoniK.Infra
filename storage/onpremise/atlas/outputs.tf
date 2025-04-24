output "host" {
  description = "MongoDB Atlas host"
  value       = local.mongodb_url.dns
}

output "url" {
  description = "MongoDB Atlas connection URL"
  value       = try(data.mongodbatlas_advanced_cluster.aklocal.connection_strings[0].standard_srv, "")
}

output "port" {
  description = "MongoDB Atlas port"
  value       = local.mongodb_port
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

output "connection_string" {
  description = "MongoDB Atlas connection string"
  value       = try(data.mongodbatlas_advanced_cluster.aklocal.connection_strings[0].standard_srv, "")
  sensitive   = true
}

# Certificate outputs - these should be null/empty if certificate download is disabled
output "ca_certificate" {
  description = "MongoDB Atlas CA certificate path"
  value       = fileexists("${path.module}/certs/ca.pem") ? "${path.module}/certs/ca.pem" : null
}

output "certificate_mount_path" {
  description = "Suggested path to mount the certificate in containers"
  value       = "/mongodb/certificate"
}

# Make the certificate secret conditional on certificate existence
output "certificate_secret" {
  description = "Kubernetes secret containing the MongoDB Atlas certificate"
  value = fileexists("${path.module}/certs/ca.pem") ? {
    name      = kubernetes_secret.mongodb_atlas_certificates[0].metadata[0].name
    namespace = kubernetes_secret.mongodb_atlas_certificates[0].metadata[0].namespace
    key       = "mongodb-ca-cert"
  } : null
}
