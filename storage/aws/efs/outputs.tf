output "id" {
  description = "EFS id"
  value       = aws_efs_file_system.efs.id
  depends_on  = [aws_efs_mount_target.efs, aws_efs_access_point.efs]
}

output "kms_key_id" {
  description = "KMS used to encrypt EFS"
  value       = aws_efs_file_system.efs.kms_key_id
  depends_on  = [aws_efs_mount_target.efs, aws_efs_access_point.efs]
}
