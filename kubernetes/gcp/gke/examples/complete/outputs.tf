output "name" {
  description = "Name of the cluster"
  value       = module.complete_gke.name
}

output "id" {
  description = "ID of the cluster"
  value       = module.complete_gke.id
}

output "location" {
  description = "Location of the cluster: its region if regional, its zone if zonal"
  value       = module.complete_gke.location
}

output "region" {
  description = "Region of the cluster"
  value       = module.complete_gke.region
}

output "zones" {
  description = "Zones of the nodes"
  value       = module.complete_gke.zones
}

output "endpoint" {
  description = "IP address of the control plane, null without IP endpoints"
  value       = module.complete_gke.endpoint
  sensitive   = true
}

output "endpoint_dns" {
  description = "DNS endpoint of the control plane"
  value       = module.complete_gke.endpoint_dns
}

output "ca_certificate" {
  description = "CA certificate of the IP endpoints of the control plane (base64 encoded)"
  value       = module.complete_gke.ca_certificate
  sensitive   = true
}

output "master_version" {
  description = "Current Kubernetes version of the control plane"
  value       = module.complete_gke.master_version
}

output "service_account" {
  description = "Email of the service account of the nodes"
  value       = module.complete_gke.service_account
}

output "compute_class_defaults" {
  description = "Settings of the node pools that ComputeClasses create"
  value       = module.complete_gke.compute_class_defaults
}

output "identity_namespace" {
  description = "Workload Identity pool of the cluster"
  value       = module.complete_gke.identity_namespace
}

output "node_pools" {
  description = "Node pools, keyed by name"
  value       = module.complete_gke.node_pools
}

output "kubeconfig_path" {
  description = "Path of the kubeconfig file of the cluster"
  value       = module.complete_gke.kubeconfig_path
}
