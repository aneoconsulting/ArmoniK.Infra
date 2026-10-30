output "service_account" {
  description = "The service account to default running nodes as if not overridden in `node_pools`."
  value       = var.service_account
}

output "node_pool_names" {
  description = "List of node pool names"
  value       = concat([for np in google_container_node_pool.pools : np.name], [for np in google_container_node_pool.windows_pools : np.name])
}

output "node_pool_versions" {
  description = "Node pool versions by node pool name"
  value       = [{ for np in google_container_node_pool.pools : np.name => np.version }, { for np in google_container_node_pool.windows_pools : np.name => np.version }]
}

output "instance_group_urls" {
  description = "List of GKE generated instance groups"
  value       = setunion([for np in google_container_node_pool.pools : np.managed_instance_group_urls], [for np in google_container_node_pool.windows_pools : np.managed_instance_group_urls])
}

output "linux_node_pool_names" {
  description = "List of Linux node pool names"
  value       = [for np in google_container_node_pool.pools : np.name]
}

output "linux_node_pool_versions" {
  description = "Linux node pool versions by node pool name"
  value       = { for np in google_container_node_pool.pools : np.name => np.version }
}

output "linux_instance_group_urls" {
  description = "List of GKE generated instance groups for Linux node pools"
  value       = distinct(flatten([for np in google_container_node_pool.pools : np.managed_instance_group_urls]))
}

output "windows_node_pool_names" {
  description = "List of Windows node pool names"
  value       = [for np in google_container_node_pool.windows_pools : np.name]
}

output "windows_node_pool_versions" {
  description = "Windows node pool versions by node pool name"
  value       = { for np in google_container_node_pool.windows_pools : np.name => np.version }
}

output "windows_instance_group_urls" {
  description = "List of GKE generated instance groups for Windows node pools"
  value       = setunion([for np in google_container_node_pool.windows_pools : np.managed_instance_group_urls])
}
