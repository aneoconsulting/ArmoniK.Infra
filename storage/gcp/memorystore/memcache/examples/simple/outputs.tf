output "id" {
  description = "The Memorystore instance ID."
  value       = module.simple_memorystore_for_mecached_instance.id
}

output "memcache_nodes" {
  description = "Additional information about the instance state, if available. The parameters: \"node_id\", \"zone\", \"port\", \"host\", \"state\"."
  value       = module.simple_memorystore_for_mecached_instance.memcache_nodes
}

output "discovery_endpoint" {
  description = "Endpoint for Discovery API"
  value       = module.simple_memorystore_for_mecached_instance.discovery_endpoint
}

output "memcache_full_version" {
  description = "The full version of memcached server running on this instance."
  value       = module.simple_memorystore_for_mecached_instance.memcache_full_version
}

