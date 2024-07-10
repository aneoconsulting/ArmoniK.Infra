output "host" {
  description = "Hostname or IP address of MongoDB server"
  value       = module.sharded_mongodb.host
}

output "port" {
  description = "Port of MongoDB server"
  value       = module.sharded_mongodb.port
}

output "url" {
  description = "URL of MongoDB server"
  value       = module.sharded_mongodb.url
}

output "number_of_shards" {
  description = "Number of MongoDB shards"
  value = module.sharded_mongodb.number_of_shards
}

output "number_of_replicas" {
  description = "Number of replicas for each shard"
  value       = module.sharded_mongodb.number_of_replicas
}

# SENSITIVE OUTPUTS
output "user_credentials" {
  description = "User credentials of MongoDB"
  value       = module.sharded_mongodb.user_credentials
  sensitive   = true
}

output "endpoints" {
  description = "Endpoints of MongoDB"
  value       = module.sharded_mongodb.endpoints
  sensitive   = true
}
