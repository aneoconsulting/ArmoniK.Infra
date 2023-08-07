output "docker_repositories" {
  description = "Docker repositories in Artifactory Registry created on GCP"
  value       = { for image, _ in null_resource.copy_images : image => "${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${image}:${var.docker_images[image].tag}" }
}

output "kms_key_name" {
  description = "KMS key name used to encrypt the registry"
  value       = var.kms_key_name
}
