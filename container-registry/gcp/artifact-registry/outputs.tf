output "url" {
  description = "URL of the virtual repository, to use as the registry of every image (global.imageRegistry in the ArmoniK charts)"
  value       = google_artifact_registry_repository.virtual.registry_uri
}

output "standard_url" {
  description = "URL of the standard repository, where private images are pushed"
  value       = one(google_artifact_registry_repository.standard[*].registry_uri)
}

output "remote_urls" {
  description = "URLs of the remote repositories, keyed by name"
  value       = { for key, repository in google_artifact_registry_repository.remote : key => repository.registry_uri }
}
