output "host" {
  description = "Hostname or IP address of MongoDB server"
  value       = module.simple_mongodb_instance.host
}

output "port" {
  description = "Port of MongoDB server"
  value       = module.simple_mongodb_instance.port
}

output "url" {
  description = "URL of MongoDB server"
  value       = module.simple_mongodb_instance.url
}

output "number_of_replicas" {
  description = "Number of replicas of MongoDB"
  value       = module.simple_mongodb_instance.number_of_replicas
}

# SENSITIVE OUTPUTS
output "user_credentials" {
  description = "User credentials of MongoDB"
  value       = module.simple_mongodb_instance.user_credentials
  sensitive   = true
}

output "endpoints" {
  description = "Endpoints of MongoDB"
  value       = module.simple_mongodb_instance.endpoints
  sensitive   = true
}
