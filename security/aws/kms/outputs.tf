output "key_arn" {
  description = "The Amazon Resource Name (ARN) of the key"
  value       = try(aws_kms_key.kms.arn, null)
}

output "key_id" {
  description = "The globally unique identifier for the key"
  value       = try(aws_kms_key.kms.key_id, null)
}

output "kms_alias" {
  description = "Alias KMS"
  value       = aws_kms_alias.kms_alias
}
