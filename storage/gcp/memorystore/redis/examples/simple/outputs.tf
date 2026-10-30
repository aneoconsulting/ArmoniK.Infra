output "id" {
  description = "The Memorystore instance ID."
  value       = module.simple_memorystore_for_redis.id
}

output "current_location_id" {
  description = "The current zone where the Redis endpoint is placed."
  value       = module.simple_memorystore_for_redis.current_location_id
}

output "host" {
  description = "The IP address of the instance."
  value       = module.simple_memorystore_for_redis.host
}

output "port" {
  description = "The port number of the exposed Redis endpoint."
  value       = module.simple_memorystore_for_redis.port
}

output "nodes" {
  description = "Info per node"
  value       = module.simple_memorystore_for_redis.nodes
}

output "region" {
  description = "The region the instance lives in."
  value       = module.simple_memorystore_for_redis.region
}
