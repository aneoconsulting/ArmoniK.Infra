output "bucket" {
    description = "bucket created on GCP"
    value       = google_storage_bucket.bucket
}

output "iam_bucket" {
    description = "The associated IAM policy"
    value       = google_storage_bucket_iam_member.role
}

output "acls_bucket" {
    description = "The associated ACLS"
    value       = google_storage_bucket_acl.acl
}