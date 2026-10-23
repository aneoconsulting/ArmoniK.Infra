output "url" {
  description = "URL of the virtual repository"
  value       = module.simple_artifact_registry.url
}

output "remote_urls" {
  description = "URLs of the remote repositories"
  value       = module.simple_artifact_registry.remote_urls
}
