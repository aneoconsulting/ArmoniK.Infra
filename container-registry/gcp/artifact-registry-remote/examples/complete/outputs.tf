output "urls" {
  description = "Image prefix of each pull-through cache"
  value       = module.complete_remote.urls
}

output "registry" {
  description = "Host of the repositories"
  value       = module.complete_remote.registry
}
