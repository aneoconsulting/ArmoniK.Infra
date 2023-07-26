output "bucket" {
    description = "bucket created on GCP"
    value       = module.simple_bucket_example.bucket
}

output "iam_bucket" {
    description = "The associated IAM policy"
    value       = module.simple_bucket_example.iam_bucket
}

output "acls_bucket" {
    description = "The associated ACLS"
    value       = module.simple_bucket_example.acls_bucket
}