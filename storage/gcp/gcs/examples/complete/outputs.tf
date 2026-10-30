output "name" {
  description = "Name of the bucket"
  value       = module.complete_gcs_bucket.name
}

output "self_link" {
  description = "The URI of the created bucket"
  value       = module.complete_gcs_bucket.self_link
}

output "url" {
  description = "The base URL of the bucket, in the format gs://<bucket-name>"
  value       = module.complete_gcs_bucket.url
}

output "access_control_id" {
  description = "An identifier for the bucket access control"
  value       = module.complete_gcs_bucket.access_control_id
}

output "access_control_domain" {
  description = "The domain associated with the bucket access control."
  value       = module.complete_gcs_bucket.access_control_domain
}

output "access_control_email" {
  description = "The email address associated with the bucket access control."
  value       = module.complete_gcs_bucket.access_control_email
}

output "acls" {
  description = "The associated ACLs"
  value       = module.complete_gcs_bucket.acls
}

output "iam_members" {
  description = "The associated IAM policy"
  value       = module.complete_gcs_bucket.iam_members
}
