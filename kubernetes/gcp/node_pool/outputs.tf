/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "service_account" {
  description = "The service account to default running nodes as if not overridden in `node_pools`."
  value       = "gke-gke-on-vpc-cluster-sa@armonik-gcp-13469.iam.gserviceaccount.com"
}

output "node_pool_names" {
  description = "List of node pool names"
  value       = concat([for np in google_container_node_pool.pools : np.name], [for np in google_container_node_pool.windows_pools : np.name])
}

output "node_pool_versions" {
  description = "Node pool versions by node pool name"
  value       = merge(
    { for np in google_container_node_pool.pools : np.name => np.version },
    { for np in google_container_node_pool.windows_pools : np.name => np.version },
  )
}

output "instance_group_urls" {
  description = "List of GKE generated instance groups"
  value       = distinct(flatten(concat([for np in google_container_node_pool.pools : np.managed_instance_group_urls], [for np in google_container_node_pool.windows_pools : np.managed_instance_group_urls])))
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
  value       = distinct(flatten([for np in google_container_node_pool.windows_pools : np.managed_instance_group_urls]))
}