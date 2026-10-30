output "name" {
  description = "Cluster name"
  value       = module.autopilot_gke.name
}

output "location" {
  description = "Cluster location (region)"
  value       = module.autopilot_gke.location
}

output "zones" {
  description = "Zones where GKE may create nodes"
  value       = module.autopilot_gke.zones
}

output "endpoint_dns" {
  description = "DNS endpoint of the control plane"
  value       = module.autopilot_gke.endpoint_dns
}

output "service_account" {
  description = "The service account of the nodes"
  value       = module.autopilot_gke.service_account
}
