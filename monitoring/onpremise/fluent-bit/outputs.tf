output "container_name" {
  description = "Container name of Fluent-bit"
  value       = var.fluent_bit.container_name
}

output "image" {
  description = "image of Fluent-bit"
  value       = var.fluent_bit.image
}

output "tag" {
  description = "tag of Fluent-bit"
  value       = var.fluent_bit.tag
}

output "is_daemonset" {
  description = "Is Fluent-bit a daemonset"
  value       = var.fluent_bit.is_daemonset
}

output "configmaps" {
  description = "Configmaps of Fluent-bit"
  value = {
    envvars = kubernetes_config_map.fluent_bit_envvars_config.metadata[0].name
    config  = kubernetes_config_map.fluent_bit_config.metadata[0].name
  }
}

output "windows_container_name" {
  description = "Container name of Fluent-bit"
  value       = var.fluent_bit_windows.container_name
}

output "windows_image" {
  description = "image of Fluent-bit"
  value       = var.fluent_bit_windows.image
}

output "windows_tag" {
  description = "tag of Fluent-bit"
  value       = var.fluent_bit_windows.tag
}

output "windows_is_daemonset" {
  description = "Is Fluent-bit a daemonset"
  value       = var.fluent_bit_windows.is_daemonset
}

output "windows_configmaps" {
  description = "Configmaps of Fluent-bit"
  value = {
    envvars = kubernetes_config_map.fluent_bit_envvars_config_windows.metadata[0].name
    config  = kubernetes_config_map.fluent_bit_config_windows.metadata[0].name
    entry   = kubernetes_config_map.fluent_bit_entrypoint.metadata[0].name
  }
}
