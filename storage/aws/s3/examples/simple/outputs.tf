output "bucket_name" {
  description = "Name of s3 bucket"
  value       = module.simple_s3.s3_bucket_name
}

output "bucket_url" {
  description = "URL of s3 bucket"
  value       = "https://s3.${var.aws_region}.amazonaws.com"
}

output "kms_key_id" {
  description = "ARN of KMS used for ECR"
  value       = module.simple_s3.kms_key_id
}
