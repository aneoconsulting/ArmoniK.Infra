output "name" {
  description = "Name of the bucket"
  value       = module.simple_bucket.name
}

output "url" {
  description = "The base URL of the bucket, in the format gs://<bucket-name>"
  value       = module.simple_bucket.url
}
