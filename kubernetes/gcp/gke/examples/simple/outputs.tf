output "name" {
  description = "Cluster name"
  value       = module.simple_gke.name
}

output "location" {
  description = "Cluster location (region if regional cluster, zone if zonal cluster)"
  value       = module.simple_gke.location
}

output "endpoint" {
  description = "Cluster endpoint"
  value       = module.simple_gke.endpoint
  sensitive   = true
}
