output "name" {
  description = "Cluster name"
  value       = module.simple_gke_autopilot.name
}

output "location" {
  description = "Cluster location (region)"
  value       = module.simple_gke_autopilot.location
}

output "endpoint" {
  description = "Cluster endpoint"
  value       = module.simple_gke_autopilot.endpoint
  sensitive   = true
}
