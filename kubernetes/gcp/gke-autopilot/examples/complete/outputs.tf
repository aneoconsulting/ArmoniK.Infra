output "name" {
  description = "Cluster name"
  value       = module.complete_gke_autopilot.name
}

output "location" {
  description = "Cluster location (region)"
  value       = module.complete_gke_autopilot.location
}

output "zones" {
  description = "Zones where GKE may create nodes"
  value       = module.complete_gke_autopilot.zones
}

output "endpoint_dns" {
  description = "DNS endpoint of the control plane"
  value       = module.complete_gke_autopilot.endpoint_dns
}

output "service_account" {
  description = "The service account of the nodes"
  value       = module.complete_gke_autopilot.service_account
}
