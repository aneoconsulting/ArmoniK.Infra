output "name" {
  description = "Cluster name"
  value       = module.complete_gke.name
}

output "location" {
  description = "Cluster location (region if regional cluster, zone if zonal cluster)"
  value       = module.complete_gke.location
}

output "endpoint_dns" {
  description = "DNS endpoint of the control plane"
  value       = module.complete_gke.endpoint_dns
}

output "node_pools" {
  description = "Kubernetes version of each node pool, keyed by name"
  value       = module.complete_gke.node_pools
}

output "service_account" {
  description = "The service account of the nodes"
  value       = module.complete_gke.service_account
}
