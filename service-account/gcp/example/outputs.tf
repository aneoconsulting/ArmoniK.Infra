output "vpc_name" {
  description = "Name of VPC"
  value = module.complete_vpc.name
}

output "gke_name" {
  description = "Name of VPC"
  value = module.gke.name
}

output "k8s_sa_name" {
  description = "Kubernetes service account name"
  value = module.service_account.k8s_sa_name
}

output "gcp_sa_name" {
  description = "Kubernetes service account name"
  value = module.service_account.gcp_sa_name
}

output "K8s_namespace" {
  description = "Kubernetes service account name"
  value = module.service_account.namespace
}