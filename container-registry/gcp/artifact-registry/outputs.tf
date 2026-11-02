output "docker_repositories" {
  description = "Docker repositories in Artifact Registry created on GCP"
  value       = { for key, value in local.docker_images : "${value.image}:${value.tag}" => "${data.google_client_config.current.region}-docker.pkg.dev/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}/${value.name}" }
}

output "kms_key_name" {
  description = "KMS key name used to encrypt the registry"
  value       = var.kms_key_id
}

output "service_account" {
  description = "The associated service account created for artifact-registry."
  value       = "service-${data.google_project.project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
}

output "url" {
  description = "URL of the virtual repository, to use as the registry of the images, or null when `pull_through_cache` is not set"
  value       = var.pull_through_cache != null ? "${local.registry_host}/${data.google_client_config.current.project}/${google_artifact_registry_repository.virtual[0].name}" : null
}

output "standard_url" {
  description = "URL of the registry created by this module, where images are pushed"
  value       = "${local.registry_host}/${data.google_client_config.current.project}/${google_artifact_registry_repository.docker.name}"
}

output "remote_urls" {
  description = "URLs of the pull-through caches, keyed by name"
  value       = { for key, repository in google_artifact_registry_repository.remote : key => "${local.registry_host}/${data.google_client_config.current.project}/${repository.name}" }
}
