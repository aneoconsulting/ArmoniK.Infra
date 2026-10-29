output "name" {
  description = "Name of the cluster"
  value       = google_container_cluster.cluster.name
}

output "id" {
  description = "ID of the cluster"
  value       = google_container_cluster.cluster.id
}

output "location" {
  description = "Location of the cluster: its region if regional or Autopilot, its zone if zonal"
  value       = google_container_cluster.cluster.location
}

output "region" {
  description = "Region of the cluster"
  value       = local.region
}

output "zones" {
  description = "Zones of the nodes"
  value       = sort(google_container_cluster.cluster.node_locations)
}

output "endpoint" {
  description = "IP address of the control plane: the private one with a private endpoint, else the public one"
  value       = var.enable_private_endpoint ? google_container_cluster.cluster.private_cluster_config[0].private_endpoint : google_container_cluster.cluster.endpoint
  sensitive   = true
}

output "endpoint_dns" {
  description = "DNS endpoint of the control plane"
  value       = google_container_cluster.cluster.control_plane_endpoints_config[0].dns_endpoint_config[0].endpoint
}

output "ca_certificate" {
  description = "CA certificate of the control plane (base64 encoded)"
  value       = google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "master_version" {
  description = "Current Kubernetes version of the control plane"
  value       = google_container_cluster.cluster.master_version
}

output "service_account" {
  description = "Email of the service account of the nodes"
  value       = local.service_account
}

output "identity_namespace" {
  description = "Workload Identity pool of the cluster"
  value       = google_container_cluster.cluster.workload_identity_config[0].workload_pool
}

output "node_pools" {
  description = "Standard only, empty on Autopilot. Kubernetes version of each node pool, keyed by name"
  value       = { for name, pool in google_container_node_pool.pools : name => pool.version }
}
