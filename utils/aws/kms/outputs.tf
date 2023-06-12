output "selected" {
  description = "Create KMS"
  value       = aws_kms_key.kms
}

output "arn" {
  description = "ARN of KMS"
  value       = aws_kms_key.kms.arn
}

output "kms_alias" {
  description = "Alias KMS"
  value       = aws_kms_alias.kms_alias
}
