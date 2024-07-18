output "env" {
  description = "Environment variables"
  value       = local.env
}

output "env_secret" {
  description = "Environment variables as secrets"
  value       = local.env_secret
}

output "mount_secret" {
  description = "Secrets to mount as volume"
  value       = local.mount_secret
}

output "env_from_secret" {
  description = "Environment variable from secrets"
  value       = local.env_from_secret
}

output "env_configmap" {
  description = "Environment variables as configmaps"
  value       = local.env_configmap
}

output "env_from_configmap" {
  description = "Environment variables from configmaps"
  value       = local.env_from_configmap
}

output "mount_configmap" {
  description = "configmaps to mount as volume"
  value       = local.mount_configmap
}
