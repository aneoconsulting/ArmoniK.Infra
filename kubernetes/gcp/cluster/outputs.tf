output "cluster_id" {
  description = "Cluster ID"
  value       = module.gke.cluster_id
}

output "name" {
  description = "Cluster name"
  value       = module.gke.name
}

output "type" {
  description = "Cluster type (regional / zonal)"
  value       = module.gke.type
}

output "location" {
  description = "Cluster location (region if regional cluster, zone if zonal cluster)"
  value       = module.gke.location
}

output "region" {
  description = "Cluster region"
  value       = module.gke.region
}

output "zones" {
  description = "List of zones in which the cluster resides"
  value       = module.gke.zones
}

output "endpoint" {
  sensitive   = true
  description = "Cluster endpoint"
  value       = module.gke.endpoint

}

output "min_master_version" {
  description = "Minimum master kubernetes version"
  value       = module.gke.min_master_version
}

output "logging_service" {
  description = "Logging service used"
  value       = module.gke.logging_service
}

output "monitoring_service" {
  description = "Monitoring service used"
  value       = module.gke.monitoring_service
}

output "master_authorized_networks_config" {
  description = "Networks from which access to master is permitted"
  value       = module.gke.master_authorized_networks_config
}

output "master_version" {
  description = "Current master kubernetes version"
  value       = module.gke.master_version
}

output "ca_certificate" {
  sensitive   = true
  description = "Cluster ca certificate (base64 encoded)"
  value       = module.gke.ca_certificate
}

output "network_policy_enabled" {
  description = "Whether network policy enabled"
  value       = module.gke.network_policy_enabled
}

output "http_load_balancing_enabled" {
  description = "Whether http load balancing enabled"
  value       = module.gke.http_load_balancing_enabled
}

output "horizontal_pod_autoscaling_enabled" {
  description = "Whether horizontal pod autoscaling enabled"
  value       = module.gke.horizontal_pod_autoscaling_enabled
}

output "vertical_pod_autoscaling_enabled" {
  description = "Whether vertical pod autoscaling enabled"
  value       = module.gke.vertical_pod_autoscaling_enabled
}

output "node_pools_names" {
  description = "List of node pools names"
  value       = module.gke.node_pools_names
}

output "node_pools_versions" {
  description = "Node pool versions by node pool name"
  value       = module.gke.node_pools_versions
}

output "service_account" {
  description = "The service account to default running nodes as if not overridden in `node_pools`."
  value       = module.gke.service_account
}

output "instance_group_urls" {
  description = "List of GKE generated instance groups"
  value       = module.gke.instance_group_urls
}

output "release_channel" {
  description = "The release channel of this cluster"
  value       = module.gke.release_channel
}

output "gateway_api_channel" {
  description = "The gateway api channel of this cluster."
  value       = module.gke.gateway_api_channel
}

output "identity_namespace" {
  description = "Workload Identity pool"
  value       = module.gke.identity_namespace
}
output "kubeconfig_path" {
  description = "value"
  value       = abspath(var.kubeconfig_path)
}
