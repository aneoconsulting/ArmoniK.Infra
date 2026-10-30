output "vpc_name" {
  description = "Name of VPC"
  value       = module.vpc.name
}

output "gke_name" {
  description = "Name of VPC"
  value       = module.gke.name
}

output "kubernetes_service_account_name" {
  description = "Kubernetes service account name"
  value       = module.service_account.kubernetes_service_account_name
}

output "gcp_service_account_name" {
  description = "Kubernetes service account name"
  value       = module.service_account.service_account_name
}

output "kubernetes_namespace" {
  description = "Kubernetes service account name"
  value       = module.service_account.namespace
}
