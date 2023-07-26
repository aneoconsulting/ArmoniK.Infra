output "bucket" {
    description = "bucket created on GCP"
    value       = module.complex_bucket_example.bucket
}

output "iam_bucket" {
    description = "The associated IAM policy"
    value       = module.complex_bucket_example.iam_bucket
}

output "acls_bucket" {
    description = "The associated ACLS"
    value       = module.complex_bucket_example.acls_bucket
}