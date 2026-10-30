output "service_account_iam_role_name" {
  description = "name of the IAM role associated to the created Kubernetes service account"
  value       = aws_iam_role.armonik.name
}

output "service_account_iam_role_arn" {
  description = "ARN of the IAM role associated to the Kubernetes service account"
  value       = aws_iam_role.armonik.arn
}

output "pod_identity_association_id" {
  description = "ID of the Pod Identity association of the service account, null when pod_identity is false. Pods get their credentials only if it exists when they start, so their workload can depend on it"
  value       = try(aws_eks_pod_identity_association.armonik[0].association_id, null)
}
