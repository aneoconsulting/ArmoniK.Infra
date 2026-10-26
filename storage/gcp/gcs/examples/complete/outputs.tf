output "name" {
  description = "Name of the bucket"
  value       = module.complete_bucket.name
}

output "url" {
  description = "The base URL of the bucket, in the format gs://<bucket-name>"
  value       = module.complete_bucket.url
}

output "log_bucket" {
  description = "Name of the bucket receiving the access logs"
  value       = module.log_bucket.name
}
