output "repositories" {
  description = "Map of ECR repositories"
  value       = module.ecr.repositories
}

output "kms_key_id" {
  description = "ARN of KMS used for ECR"
  value       = module.ecr.kms_key_id
}
