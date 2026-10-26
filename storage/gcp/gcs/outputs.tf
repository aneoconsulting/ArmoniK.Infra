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
