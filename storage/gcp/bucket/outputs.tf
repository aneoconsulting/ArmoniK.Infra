output "bucket" {
    description = "bucket created on GCP"
    value       = google_storage_bucket.bucket_creation
}

output "iam_bucket" {
    description = "The associated IAM policy"
    value       = google_storage_bucket_iam_binding.bucket_policy_creation
}

output "acls_bucket" {
    description = "The associated ACLS"
    value       = google_storage_bucket_acl.bucket_acls_creation
}