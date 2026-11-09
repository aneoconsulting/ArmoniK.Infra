output "connection" {
  description = "Connection parameters of the instance"
  value = {
    host     = module.complete_cloudsql.host
    port     = module.complete_cloudsql.port
    database = module.complete_cloudsql.database
    username = module.complete_cloudsql.username
  }
}

output "password" {
  description = "Password of the PostgreSQL user"
  value       = module.complete_cloudsql.password
  sensitive   = true
}

output "ca_cert" {
  description = "CA certificates of the server certificate"
  value       = module.complete_cloudsql.ca_cert
  sensitive   = true
}
