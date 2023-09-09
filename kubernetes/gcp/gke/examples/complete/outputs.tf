output "ca_certificate" {
  sensitive   = true
  description = "Cluster ca certificate (base64 encoded)."
  value       = module.gke.ca_certificate
}

output "cluster_id" {
  description = "GKE cluster ID."
  value       = module.gke.cluster_id
}

output "endpoint" {
  description = "Cluster endpoint"
  value       = module.gke.endpoint
  sensitive   = true
}

output "intranode_visibility_enabled" {
  description = "Whether intra-node visibility is enabled."
  value = module.gke.intranode_visibility_enabled
}

output "istio_enabled" {
  description = "Whether Istio is enabled."
  value = module.gke.istio_enabled
}

output "kubeconfig_path" {
  description = "Path where the kubeconfig file is saved."
  value       = module.gke.kubeconfig_path
}

output "location" {
  description = "Cluster location (region if regional cluster, zone if zonal cluster)"
  value       = module.gke.location
}

output "name" {
  description = "GKE cluster name."
  value       = module.gke.name
}

output "node_pools_names" {
  description = "List of node pools names."
  value       = module.gke.node_pools_names
}

output "region" {
  description = "Cluster region."
  value       = module.gke.region
}

output "service_account" {
  description = "The service account to default running nodes as if not overridden in `node_pools`."
  value       = module.gke.service_account
}

output "type" {
  description = "GKE cluster type (regional / zonal)."
  value       = module.gke.type
}

output "zones" {
  description = "List of zones in which the cluster resides"
  value       = module.gke.zones
}
