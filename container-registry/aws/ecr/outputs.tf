output "repositories" {
  description = "Map of ECR repositories created on AWS"
  value       = { for repo in aws_ecr_repository.ecr : repo.name => repo.repository_url }
}

output "kms_key_id" {
  description = "ARN of KMS used for ECR"
  value       = var.kms_key_id
}
