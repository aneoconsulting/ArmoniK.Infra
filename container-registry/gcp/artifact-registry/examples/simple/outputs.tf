output "docker_repositories" {
  description = "Docker repositories in Artifact Registry created on GCP"
  value       = module.simple_artifact_registry.docker_repositories
}

output "kms_key_name" {
  description = "KMS key name used to encrypt the registry"
  value       = module.simple_artifact_registry.kms_key_name
}

output "service_account" {
  description = "The associated service account created for artifact-registry."
  value       = module.simple_artifact_registry.service_account
}

output "url" {
  description = "URL of the virtual repository"
  value       = module.simple_artifact_registry.url
}

output "standard_url" {
  description = "URL of the registry where images are pushed"
  value       = module.simple_artifact_registry.standard_url
}

output "remote_urls" {
  description = "URLs of the pull-through caches"
  value       = module.simple_artifact_registry.remote_urls
}
