output "member" {
  description = "IAM member of the Kubernetes service account"
  value       = module.simple_service_account.member
}
