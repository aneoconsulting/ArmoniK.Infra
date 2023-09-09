output "ca_certificate" {
  sensitive   = true
  description = "Cluster ca certificate (base64 encoded)."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].ca_certificate : null),
    (local.private_gke ? module.private_gke[0].ca_certificate : null),
  ), null)
}

output "cloudrun_enabled" {
  description = "Whether CloudRun enabled."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].cloudrun_enabled : null),
    (local.private_gke ? module.private_gke[0].cloudrun_enabled : null),
  ), null)
}

output "cluster_id" {
  description = "GKE cluster ID."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].cluster_id : null),
    (local.private_gke ? module.private_gke[0].cluster_id : null),
  ), null)
}

output "dns_cache_enabled" {
  description = "Whether DNS Cache enabled"
  value = try(coalesce(
    (local.public_gke ? module.gke[0].dns_cache_enabled : null),
    (local.private_gke ? module.private_gke[0].dns_cache_enabled : null),
  ), null)
}

output "endpoint" {
  description = "Cluster endpoint."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].endpoint : null),
    (local.private_gke ? module.private_gke[0].endpoint : null),
  ), null)
  sensitive = true
}

output "identity_namespace" {
  description = "Workload Identity pool."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].identity_namespace : null),
    (local.private_gke ? module.private_gke[0].identity_namespace : null),
  ), null)
}

output "identity_service_enabled" {
  description = "Whether Identity Service is enabled."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].identity_service_enabled : null),
    (local.private_gke ? module.private_gke[0].identity_service_enabled : null),
  ), null)
}

output "instance_group_urls" {
  description = "List of GKE generated instance groups."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].instance_group_urls : null),
    (local.private_gke ? module.private_gke[0].instance_group_urls : null),
  ), null)
}

output "intranode_visibility_enabled" {
  description = "Whether intra-node visibility is enabled."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].intranode_visibility_enabled : null),
    (local.private_gke ? module.private_gke[0].intranode_visibility_enabled : null),
  ), null)
}

output "istio_enabled" {
  description = "Whether Istio is enabled."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].istio_enabled : null),
    (local.private_gke ? module.private_gke[0].istio_enabled : null),
  ), null)
}

output "kubeconfig_path" {
  description = "Path where the kubeconfig file is saved."
  value       = can(coalesce(var.kubeconfig_path)) ? abspath(var.kubeconfig_path) : ""
}

output "location" {
  description = "Cluster location (region if regional cluster, zone if zonal cluster)."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].location : null),
    (local.private_gke ? module.private_gke[0].location : null),
  ), null)
}

output "master_version" {
  description = "Current master kubernetes version."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].master_version : null),
    (local.private_gke ? module.private_gke[0].master_version : null),
  ), null)
}

output "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation used for the hosted master network."
  value       = local.private_gke ? module.private_gke[0].master_ipv4_cidr_block : ""
}

output "min_master_version" {
  description = "Minimum master kubernetes version."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].master_version : null),
    (local.private_gke ? module.private_gke[0].master_version : null),
  ), null)
}

output "name" {
  description = "GKE cluster name."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].name : null),
    (local.private_gke ? module.private_gke[0].name : null),
  ), null)
}

output "node_pools_names" {
  description = "List of node pools names."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].node_pools_names : null),
    (local.private_gke ? module.private_gke[0].node_pools_names : null),
  ), null)
}

output "region" {
  description = "Cluster region."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].region : null),
    (local.private_gke ? module.private_gke[0].region : null),
  ), null)
}

output "service_account" {
  description = "The service account to default running nodes as if not overridden in `node_pools`."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].service_account : null),
    (local.private_gke ? module.private_gke[0].service_account : null),
  ), null)
}

output "type" {
  description = "GKE cluster type (regional / zonal)."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].type : null),
    (local.private_gke ? module.private_gke[0].type : null),
  ), null)
}

output "peering_name" {
  description = "The name of the peering between this cluster and the Google owned VPC."
  value       = local.private_gke ? module.private_gke[0].peering_name : ""
}

output "pod_security_policy_enabled" {
  description = "Whether pod security policy is enabled."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].pod_security_policy_enabled : null),
    (local.private_gke ? module.private_gke[0].pod_security_policy_enabled : null),
  ), null)
}

output "tpu_ipv4_cidr_block" {
  description = "The IP range in CIDR notation used for the TPUs"
  value = try(coalesce(
    (local.public_gke ? module.gke[0].tpu_ipv4_cidr_block : null),
    (local.private_gke ? module.private_gke[0].tpu_ipv4_cidr_block : null),
  ), null)
}

output "zones" {
  description = "List of zones in which the cluster resides"
  value = try(coalesce(
    (local.public_gke ? module.gke[0].zones : null),
    (local.private_gke ? module.private_gke[0].zones : null),
  ), null)
}

# Not needed yet
output "gateway_api_channel" {
  description = "The gateway api channel of this cluster."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].gateway_api_channel : null),
    (local.private_gke ? module.private_gke[0].gateway_api_channel : null),
  ), null)
}

output "horizontal_pod_autoscaling_enabled" {
  description = "Whether horizontal pod autoscaling enabled."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].horizontal_pod_autoscaling_enabled : null),
    (local.private_gke ? module.private_gke[0].horizontal_pod_autoscaling_enabled : null),
  ), null)
}

output "http_load_balancing_enabled" {
  description = "Whether http load balancing enabled."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].http_load_balancing_enabled : null),
    (local.private_gke ? module.private_gke[0].http_load_balancing_enabled : null),
  ), null)
}

output "logging_service" {
  description = "Logging service used."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].logging_service : null),
    (local.private_gke ? module.private_gke[0].logging_service : null),
  ), null)
}

output "master_authorized_networks_config" {
  description = "Networks from which access to master is permitted."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].master_authorized_networks_config : null),
    (local.private_gke ? module.private_gke[0].master_authorized_networks_config : null),
  ), null)
}

output "monitoring_service" {
  description = "Monitoring service used."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].monitoring_service : null),
    (local.private_gke ? module.private_gke[0].monitoring_service : null),
  ), null)
}

output "network_policy_enabled" {
  description = "Whether network policy enabled."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].network_policy_enabled : null),
    (local.private_gke ? module.private_gke[0].network_policy_enabled : null),
  ), null)
}

output "node_pools_versions" {
  description = "Node pool versions by node pool name."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].node_pools_versions : null),
    (local.private_gke ? module.private_gke[0].node_pools_versions : null),
  ), null)
}

output "release_channel" {
  description = "The release channel of this cluster."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].release_channel : null),
    (local.private_gke ? module.private_gke[0].release_channel : null),
  ), null)
}

output "vertical_pod_autoscaling_enabled" {
  description = "Whether vertical pod autoscaling enabled."
  value = try(coalesce(
    (local.public_gke ? module.gke[0].vertical_pod_autoscaling_enabled : null),
    (local.private_gke ? module.private_gke[0].vertical_pod_autoscaling_enabled : null),
  ), null)
}
