output "namespace" {
  description = "Namespace within which name of the service account must be unique."
  value       = try(kubernetes_service_account.pods[0].metadata[0].namespace, var.kubernetes_namespace)
}

output "kubernetes_service_account_name" {
  description = "Name of Kubernetes service account."
  value       = try(kubernetes_service_account.pods[0].metadata[0].name, var.name)
}

output "service_account_name" {
  description = "Name of GCP service account, null without iam_service_account."
  value       = one(google_service_account.pods[*].name)
}

output "service_account_email" {
  description = "The e-mail address of the GCP service account, null without iam_service_account."
  value       = one(google_service_account.pods[*].email)
}

output "service_account_id" {
  description = "The ID of the GCP service account, null without iam_service_account."
  value       = one(google_service_account.pods[*].id)
}

output "service_account_roles" {
  description = "The IAM roles associated with the GCP service account."
  value       = { for key, value in google_project_iam_member.workload_identity_sa_bindings : key => value.role }
}

output "member" {
  description = "IAM member holding the roles: the GCP service account, or the Kubernetes service account itself without iam_service_account. To grant roles on resources (roles inputs of the gcs and kms modules for instance)."
  value       = local.member
}
