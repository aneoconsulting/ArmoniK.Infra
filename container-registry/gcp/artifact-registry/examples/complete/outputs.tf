output "docker_repositories" {
  description = "Docker repositories in Artifactory Registry created on GCP"
  value       = module.complete_artifact_registry.docker_repositories 
}

output "kms_key_name" {
  description = "KMS key name used to encrypt the registry"
  value       = module.complete_artifact_registry.kms_key_name
}
