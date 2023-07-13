output "region" {
  description = "Region used for the subnets"
  value       = var.region
}

output "enable_external_access" {
  description = "Boolean to disable external access"
  value       = var.enable_external_access
}

output "name" {
  description = "The name of the VPC"
  value       = google_compute_network.vpc.name
}

output "private_subnets" {
  description = "List of private subnets"
  value       = google_compute_subnetwork.private_subnets
}

output "public_subnets" {
  description = "List  of public subnets"
  value       = google_compute_subnetwork.public_subnets
}

output "id" {
  description = "The VPC"
  value       = google_compute_network.vpc
}

output "pod_subnets" {
  description = "List of Pods subnets"
  value       = google_compute_subnetwork.pod_subnets
}