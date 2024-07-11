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
