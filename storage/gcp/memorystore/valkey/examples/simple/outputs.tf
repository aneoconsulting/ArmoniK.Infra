output "url" {
  description = "Address of the primary endpoint"
  value       = module.simple_valkey.url
}

output "auth_token" {
  description = "Password of the default user"
  value       = module.simple_valkey.auth_token
  sensitive   = true
}
