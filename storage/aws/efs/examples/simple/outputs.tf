output "efs_id" {
  description = "Id of AWS EFS"
  value       = module.efs.id
}

output "kms_key_id" {
  description = "ID of KMS key"
  value       = module.efs.kms_key_id
}
