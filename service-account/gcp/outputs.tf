output "member" {
  description = "IAM member of the Kubernetes service account, to grant roles on resources (roles inputs of the gcs, kms and artifact-registry modules for instance)"
  value       = local.member
}
