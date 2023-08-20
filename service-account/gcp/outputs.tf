output "namespace" {
  description = "Namespace within which name of the service account must be unique."
  value       = kubernetes_service_account.pods.metadata[0].namespace
}

output "kubernetes_service_account_name" {
  description = "Name of Kubernetes service account."
  value       = kubernetes_service_account.pods.metadata[0].name
}

output "service_account_name" {
  description = "Name of GCP service account."
  value       = google_service_account.pods.name
}

output "service_account_email" {
  description = "The e-mail address of the GCP service account."
  value       = google_service_account.pods.email
}

output "service_account_id" {
  description = "The ID of the GCP service account."
  value       = google_service_account.pods.id
}

output "service_account_roles" {
  description = "The IAM roles associated with the GCP service account."
  value       = { for key, value in google_project_iam_member.workload_identity_sa_bindings : key => value.role }
}
