output "ca_certificate" {
  sensitive   = true
  description = "Cluster ca certificate (base64 encoded)."
  value       = var.private ? module.private_gke[0].ca_certificate : module.gke[0].ca_certificate
}

output "cluster_id" {
  description = "GKE cluster ID."
  value       = var.private ? module.private_gke[0].cluster_id : module.gke[0].cluster_id
}

output "endpoint" {
  description = "Cluster endpoint."
  value       = var.private ? module.private_gke[0].endpoint : module.gke[0].endpoint
  sensitive   = true
}

output "identity_namespace" {
  description = "Workload Identity pool."
  value       = var.private ? module.private_gke[0].identity_namespace : module.gke[0].identity_namespace
}

output "instance_group_urls" {
  description = "List of GKE generated instance groups."
  value       = var.private ? module.private_gke[0].instance_group_urls : module.gke[0].instance_group_urls
}

output "kubeconfig_path" {
  description = "Path where the kubeconfig file is saved."
  value       = can(coalesce(var.kubeconfig_path)) ? abspath(var.kubeconfig_path) : ""
}

output "location" {
  description = "Cluster location (region if regional cluster, zone if zonal cluster)."
  value       = var.private ? module.private_gke[0].location : module.gke[0].location
}

output "master_version" {
  description = "Current master kubernetes version."
  value       = var.private ? module.private_gke[0].master_version : module.gke[0].master_version
}

output "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation used for the hosted master network."
  value       = var.private ? module.private_gke[0].master_ipv4_cidr_block : ""
}

output "min_master_version" {
  description = "Minimum master kubernetes version."
  value       = var.private ? module.private_gke[0].min_master_version : module.gke[0].min_master_version
}

output "name" {
  description = "GKE cluster name."
  value       = var.private ? module.private_gke[0].name : module.gke[0].name
}

output "node_pools_names" {
  description = "List of node pools names."
  value       = var.private ? module.private_gke[0].node_pools_names : module.gke[0].node_pools_names
}

output "region" {
  description = "Cluster region."
  value       = var.private ? module.private_gke[0].region : module.gke[0].region
}

output "service_account" {
  description = "The service account to default running nodes as if not overridden in `node_pools`."
  value       = var.private ? module.private_gke[0].service_account : module.gke[0].service_account
}

output "type" {
  description = "GKE cluster type (regional / zonal)."
  value       = var.private ? module.private_gke[0].type : module.gke[0].type
}

output "peering_name" {
  description = "The name of the peering between this cluster and the Google owned VPC."
  value       = var.private ? module.private_gke[0].peering_name : ""
}

output "zones" {
  description = "List of zones in which the cluster resides"
  value       = var.private ? module.private_gke[0].zones : module.gke[0].zones
}

# Not needed yet
output "gateway_api_channel" {
  description = "The gateway api channel of this cluster."
  value       = var.private ? module.private_gke[0].gateway_api_channel : module.gke[0].gateway_api_channel
}

output "horizontal_pod_autoscaling_enabled" {
  description = "Whether horizontal pod autoscaling enabled."
  value       = var.private ? module.private_gke[0].horizontal_pod_autoscaling_enabled : module.gke[0].horizontal_pod_autoscaling_enabled
}

output "http_load_balancing_enabled" {
  description = "Whether http load balancing enabled."
  value       = var.private ? module.private_gke[0].http_load_balancing_enabled : module.gke[0].http_load_balancing_enabled
}

output "logging_service" {
  description = "Logging service used."
  value       = var.private ? module.private_gke[0].logging_service : module.gke[0].logging_service
}

output "master_authorized_networks_config" {
  description = "Networks from which access to master is permitted."
  value       = var.private ? module.private_gke[0].master_authorized_networks_config : module.gke[0].master_authorized_networks_config
}

output "monitoring_service" {
  description = "Monitoring service used."
  value       = var.private ? module.private_gke[0].monitoring_service : module.gke[0].monitoring_service
}

output "network_policy_enabled" {
  description = "Whether network policy enabled."
  value       = var.private ? module.private_gke[0].network_policy_enabled : module.gke[0].network_policy_enabled
}

output "node_pools_versions" {
  description = "Node pool versions by node pool name."
  value       = var.private ? module.private_gke[0].node_pools_versions : module.gke[0].node_pools_versions
}

output "release_channel" {
  description = "The release channel of this cluster."
  value       = var.private ? module.private_gke[0].release_channel : module.gke[0].release_channel
}

output "vertical_pod_autoscaling_enabled" {
  description = "Whether vertical pod autoscaling enabled."
  value       = var.private ? module.private_gke[0].vertical_pod_autoscaling_enabled : module.gke[0].vertical_pod_autoscaling_enabled
}
