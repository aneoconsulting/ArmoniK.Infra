output "urls" {
  description = "Image prefix of each pull-through cache, keyed like var.repositories: <location>-docker.pkg.dev/<project>/<repository>. The upstream path of an image follows it."
  value       = { for key, repository in google_artifact_registry_repository.remote : key => "${local.registry}/${local.project}/${repository.repository_id}" }
}

output "registry" {
  description = "Host of the repositories, <location>-docker.pkg.dev, for a registry login"
  value       = local.registry
}

output "ids" {
  description = "IDs of the repositories (projects/<project>/locations/<location>/repositories/<repository>), keyed like var.repositories"
  value       = { for key, repository in google_artifact_registry_repository.remote : key => repository.id }
}
