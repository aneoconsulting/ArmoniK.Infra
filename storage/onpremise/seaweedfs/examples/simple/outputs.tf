output "url" {
  description = "URL of the SeaweedFS S3 service"
  value       = module.simple_seaweedfs_instance.url
}

output "bucket_name" {
  description = "Name of the SeaweedFS bucket"
  value       = module.simple_seaweedfs_instance.bucket_name
}

output "env" {
  description = "Elements to be set as environment variables"
  value       = module.simple_seaweedfs_instance.env
}

output "env_secret" {
  description = "Secrets to be set as environment variables"
  value       = module.simple_seaweedfs_instance.env_secret
}
