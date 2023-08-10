output "id" {
  description = "The Memorystore instance ID."
  value       = google_memcache_instance.cache.id
}

output "memcache_nodes" {
  description = "Additional information about the instance state, if available. The parameters: \"node_id\", \"zone\", \"port\", \"host\", \"state\"."
  value       = google_memcache_instance.cache.memcache_nodes
}

output "discovery_endpoint" {
  description = "Endpoint for Discovery API"
  value       = google_memcache_instance.cache.discovery_endpoint
}

output "memcache_full_version" {
  description = "The full version of memcached server running on this instance."
  value       = google_memcache_instance.cache.memcache_full_version
}

