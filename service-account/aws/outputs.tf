output "service_account_iam_role_name" {
  description = "name of the IAM role associated to the created Kubernetes service account"
  value       = aws_iam_role.armonik.name
}
