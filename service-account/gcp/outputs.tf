output "namespace" {
  description = "Namespace within which name of the service account must be unique"
  value       = kubernetes_service_account.pods.metadata[0].namespace
}

output "k8s_sa_name" {
  description = "Name of Kubernetes service account"
  value       = kubernetes_service_account.pods.metadata[0].name
}

output "gcp_sa_name" {
  description = "Name of GCP service account"
  value       = google_service_account.pods.name
}
