output "bucket" {
  description = "bucket created on GCP"
  value       = google_storage_bucket.gcs
}

output "name" {
  description = "Name of the bucket"
  value       = google_storage_bucket.gcs.name
}

output "self_link" {
  description = "The URI of the created bucket"
  value       = google_storage_bucket.gcs.self_link
}

output "url" {
  description = "The base URL of the bucket, in the format gs://<bucket-name>"
  value       = google_storage_bucket.gcs.url
}

output "access_control_id" {
  description = "An identifier for the bucket access control"
  value       = one(google_storage_bucket_access_control.access_control[*].id)
}

output "access_control_domain" {
  description = "The domain associated with the bucket access control."
  value       = one(google_storage_bucket_access_control.access_control[*].domain)
}

output "access_control_email" {
  description = "The email address associated with the bucket access control."
  value       = one(google_storage_bucket_access_control.access_control[*].email)
}

output "acls" {
  description = "The associated ACLs"
  value       = try(google_storage_bucket_acl.default_acl[0], google_storage_bucket_acl.predefined_acl[0], google_storage_bucket_acl.role_entity_acl[0], null)
}

output "iam_members" {
  description = "The associated IAM policy"
  value       = google_storage_bucket_iam_member.role
}

#new outputs
output "env" {
  description = "Elements to be set as environment variables"
  value = ({
    "Components__ObjectStorage" = var.object_storage_adapter
    "S3__BucketName"            = google_storage_bucket.gcs.name
    "S3__UseChecksum"           = false
    "S3__MustForcePathStyle"    = false
    "S3__UseChunkEncoding"      = false
    "S3__EndpointUrl"           = "https://storage.googleapis.com"
  })
}

output "env_secret" {
  description = "Secrets to be set as environment variables"
  value = [
    kubernetes_secret.s3_user_credentials.metadata[0].name
  ]
}
