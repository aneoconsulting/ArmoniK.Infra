output "s3_bucket_name" {
  description = "Name of S3 bucket"
  value       = aws_s3_bucket.s3_bucket.id
}

output "kms_key_id" {
  description = "ARN of KMS used for S3"
  value       = var.kms_key_id
}

output "arn" {
  description = "ARN S3"
  value       = aws_s3_bucket.s3_bucket.arn
}

#new outputs
output "env" {
  description = "Elements to be set as environment variables"
  value = ({
    "Components__ObjectStorage" = var.object_storage_adapter
    "S3__BucketName"            = aws_s3_bucket.s3_bucket.bucket
    "S3__UseChecksum"           = true
    "S3__MustForcePathStyle"    = true
    "S3__UseChunkEncoding"      = true
    "S3__EndpointUrl"           = "https://s3.${aws_s3_bucket.s3_bucket.region}.amazonaws.com"
  })
}
