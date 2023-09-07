output "ca_certificate" {
  sensitive   = true
  description = "Cluster ca certificate (base64 encoded)."
  value       = module.gke_standard.ca_certificate
}

output "cluster_id" {
  description = "GKE cluster ID."
  value       = module.gke_standard.cluster_id
}

output "endpoint" {
  description = "Cluster endpoint"
  value       = module.gke_standard.endpoint
  sensitive   = true
}

output "identity_namespace" {
  description = "Workload Identity pool."
  value       = module.gke_standard.identity_namespace
}

output "instance_group_urls" {
  description = "List of GKE generated instance groups"
  value       = module.gke_standard.instance_group_urls
}

output "kubeconfig_path" {
  description = "Path where the kubeconfig file is saved."
  value       = can(coalesce(var.kubeconfig_path)) ? abspath(var.kubeconfig_path) : ""
}

output "location" {
  description = "Cluster location (region if regional cluster, zone if zonal cluster)"
  value       = module.gke_standard.location
}

output "master_version" {
  description = "Current master kubernetes version."
  value       = module.gke_standard.master_version
}

output "min_master_version" {
  description = "Minimum master kubernetes version"
  value       = module.gke_standard.min_master_version
}

output "name" {
  description = "GKE cluster name."
  value       = module.gke_standard.name
}

output "node_pools_names" {
  description = "List of node pools names."
  value       = module.gke_standard.node_pools_names
}

output "region" {
  description = "Cluster region."
  value       = module.gke_standard.region
}

output "service_account" {
  description = "The service account to default running nodes as if not overridden in `node_pools`."
  value       = module.gke_standard.service_account
}

output "type" {
  description = "GKE cluster type (regional / zonal)."
  value       = module.gke_standard.type
}

output "zones" {
  description = "List of zones in which the cluster resides"
  value       = module.gke_standard.zones
}

# Not needed yet
output "gateway_api_channel" {
  description = "The gateway api channel of this cluster."
  value       = module.gke_standard.gateway_api_channel
}

output "horizontal_pod_autoscaling_enabled" {
  description = "Whether horizontal pod autoscaling enabled."
  value       = module.gke_standard.horizontal_pod_autoscaling_enabled
}

output "http_load_balancing_enabled" {
  description = "Whether http load balancing enabled."
  value       = module.gke_standard.http_load_balancing_enabled
}

output "logging_service" {
  description = "Logging service used."
  value       = module.gke_standard.logging_service
}

output "master_authorized_networks_config" {
  description = "Networks from which access to master is permitted."
  value       = module.gke_standard.master_authorized_networks_config
}

output "monitoring_service" {
  description = "Monitoring service used."
  value       = module.gke_standard.monitoring_service
}

output "network_policy_enabled" {
  description = "Whether network policy enabled."
  value       = module.gke_standard.network_policy_enabled
}

output "node_pools_versions" {
  description = "Node pool versions by node pool name."
  value       = module.gke_standard.node_pools_versions
}

output "release_channel" {
  description = "The release channel of this cluster."
  value       = module.gke_standard.release_channel
}

output "vertical_pod_autoscaling_enabled" {
  description = "Whether vertical pod autoscaling enabled."
  value       = module.gke_standard.vertical_pod_autoscaling_enabled
}
