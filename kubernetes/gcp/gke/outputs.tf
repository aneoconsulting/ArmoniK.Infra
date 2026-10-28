output "name" {
  description = "Cluster name"
  value       = local.cluster.name
}

output "cluster_id" {
  description = "Cluster ID"
  value       = local.cluster.cluster_id
}

output "location" {
  description = "Cluster location (region if regional or Autopilot cluster, zone if zonal cluster)"
  value       = local.cluster.location
}

output "region" {
  description = "Cluster region"
  value       = local.cluster.region
}

output "zones" {
  description = "List of zones in which the cluster resides"
  value       = local.cluster.zones
}

output "endpoint" {
  description = "Cluster endpoint"
  value       = local.cluster.endpoint
  sensitive   = true
}

output "endpoint_dns" {
  description = "Cluster endpoint DNS"
  value       = local.cluster.endpoint_dns
}

output "ca_certificate" {
  description = "Cluster ca certificate (base64 encoded)"
  value       = local.cluster.ca_certificate
  sensitive   = true
}

output "master_version" {
  description = "Current master kubernetes version"
  value       = local.cluster.master_version
}

output "min_master_version" {
  description = "Minimum master kubernetes version"
  value       = local.cluster.min_master_version
}

output "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation used for the hosted master network"
  value       = local.cluster.master_ipv4_cidr_block
}

output "master_authorized_networks_config" {
  description = "Networks from which access to master is permitted"
  value       = local.cluster.master_authorized_networks_config
}

output "peering_name" {
  description = "The name of the peering between this cluster and the Google owned VPC."
  value       = local.cluster.peering_name
}

output "release_channel" {
  description = "The release channel of this cluster"
  value       = local.cluster.release_channel
}

output "service_account" {
  description = "The service account of the nodes, by default for the Standard node pools that do not set one"
  value       = local.cluster.service_account
}

output "identity_namespace" {
  description = "Workload Identity pool"
  value       = local.cluster.identity_namespace
}

output "node_pools_names" {
  description = "Standard only, null on Autopilot. List of node pools names"
  # Upstream appends "" after the Linux and the Windows pool names
  value = one([for names in module.standard[*].node_pools_names : compact(names)])
}

output "node_pools_versions" {
  description = "Standard only, null on Autopilot. Node pool versions by node pool name"
  value       = one(module.standard[*].node_pools_versions)
}

output "instance_group_urls" {
  description = "Standard only, null on Autopilot. List of GKE generated instance groups"
  value       = one(module.standard[*].instance_group_urls)
}

output "logging_service" {
  description = "Logging service used"
  value       = local.cluster.logging_service
}

output "monitoring_service" {
  description = "Monitoring service used"
  value       = local.cluster.monitoring_service
}

output "network_policy_enabled" {
  description = "Standard only, null on Autopilot. Whether network policy enabled"
  value       = one(module.standard[*].network_policy_enabled)
}

output "http_load_balancing_enabled" {
  description = "Whether http load balancing enabled"
  value       = local.cluster.http_load_balancing_enabled
}

output "horizontal_pod_autoscaling_enabled" {
  description = "Whether horizontal pod autoscaling enabled"
  value       = local.cluster.horizontal_pod_autoscaling_enabled
}

output "vertical_pod_autoscaling_enabled" {
  description = "Whether vertical pod autoscaling enabled"
  value       = local.cluster.vertical_pod_autoscaling_enabled
}

output "gateway_api_channel" {
  description = "The gateway api channel of this cluster."
  value       = local.cluster.gateway_api_channel
}

output "dns_cache_enabled" {
  description = "Whether DNS Cache enabled"
  value       = local.cluster.dns_cache_enabled
}

output "identity_service_enabled" {
  description = "Whether Identity Service is enabled"
  value       = local.cluster.identity_service_enabled
}

output "intranode_visibility_enabled" {
  description = "Whether intra-node visibility is enabled"
  value       = local.cluster.intranode_visibility_enabled
}

output "tpu_ipv4_cidr_block" {
  description = "The IP range in CIDR notation used for the TPUs"
  value       = local.cluster.tpu_ipv4_cidr_block
}
