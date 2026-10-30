output "service_account" {
  description = "The service account to default running nodes as if not overridden in `node_pools`."
  value       = module.node_pool.service_account
}

output "node_pool_names" {
  description = "List of node pool names"
  value       = module.node_pool.node_pool_names
}

output "node_pool_versions" {
  description = "Node pool versions by node pool name"
  value       = module.node_pool.node_pool_versions
}

output "instance_group_urls" {
  description = "List of GKE generated instance groups"
  value       = module.node_pool.instance_group_urls
}

output "linux_node_pool_names" {
  description = "List of Linux node pool names"
  value       = module.node_pool.linux_node_pool_names
}

output "linux_node_pool_versions" {
  description = "Linux node pool versions by node pool name"
  value       = module.node_pool.linux_node_pool_versions
}

output "linux_instance_group_urls" {
  description = "List of GKE generated instance groups for Linux node pools"
  value       = module.node_pool.linux_instance_group_urls
}

output "windows_node_pool_names" {
  description = "List of Windows node pool names"
  value       = module.node_pool.windows_node_pool_names
}

output "windows_node_pool_versions" {
  description = "Windows node pool versions by node pool name"
  value       = module.node_pool.windows_node_pool_versions
}

output "windows_instance_group_urls" {
  description = "List of GKE generated instance groups for Windows node pools"
  value       = module.node_pool.windows_instance_group_urls
}
