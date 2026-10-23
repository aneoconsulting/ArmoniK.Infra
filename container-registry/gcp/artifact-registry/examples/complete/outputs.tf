output "url" {
  description = "URL of the virtual repository"
  value       = module.complete_artifact_registry.url
}

output "remote_urls" {
  description = "URLs of the remote repositories"
  value       = module.complete_artifact_registry.remote_urls
}

output "standard_url" {
  description = "URL of the standard repository"
  value       = module.complete_artifact_registry.standard_url
}
