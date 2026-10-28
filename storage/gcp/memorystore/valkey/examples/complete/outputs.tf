output "url" {
  description = "Address of the primary endpoint"
  value       = module.complete_valkey.url
}

output "auth_token" {
  description = "Password of the default user"
  value       = module.complete_valkey.auth_token
  sensitive   = true
}

output "reader_url" {
  description = "Address of the reader endpoint"
  value       = module.complete_valkey.reader_url
}

output "ca_certificates" {
  description = "PEM certificates of the server CA"
  value       = module.complete_valkey.ca_certificates
}

output "network" {
  description = "Name of the VPC"
  value       = module.vpc.name
}
