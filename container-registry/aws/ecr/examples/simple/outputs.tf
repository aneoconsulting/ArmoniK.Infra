output "repositories" {
  description = "Map of ECR repositories"
  value       = module.simple_ecr.repositories
}

output "kms_key_id" {
  description = "ARN of KMS used for ECR"
  value       = module.simple_ecr.kms_key_id
}
