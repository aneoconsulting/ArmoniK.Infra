output "docker_repositories" {
  description = "Docker repositories in Artifactory Registry created on GCP"
  value       = { for key, value in null_resource.copy_images : "${value.image}:${value.tag}" => "${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${value.name}:${value.tag}" }
}

output "kms_key_name" {
  description = "KMS key name used to encrypt the registry"
  value       = var.kms_key_name
}
