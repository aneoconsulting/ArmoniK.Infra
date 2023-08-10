/**
 * Copyright 2020 Google LLC
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
output "kubeconfig_raw" {
  sensitive   = true
  description = "A kubeconfig file configured to access the GKE cluster."
  value = templatefile("${path.module}/kubeconfig-template.yaml.tpl", {
    context                = local.context
    cluster_ca_certificate = local.cluster_ca_certificate
    endpoint               = local.endpoint
    token                  = data.google_client_config.provider.access_token
  })
}

output "service_account" {
  description = "The service account to default running nodes as if not overridden in `node_pools`."
  value       = module.gke.service_account
}

output "node_pool_names" {
  description = "List of node pool names"
  value       = module.gke.node_pool_names
}

output "node_pool_versions" {
  description = "Node pool versions by node pool name"
  value       = module.gke.node_pool_versions
}

output "instance_group_urls" {
  description = "List of GKE generated instance groups"
  value       = module.gke.instance_group_urls
}

output "linux_node_pool_names" {
  description = "List of Linux node pool names"
  value       = module.gke.linux_node_pool_names
}

output "linux_node_pool_versions" {
  description = "Linux node pool versions by node pool name"
  value       = module.gke.linux_node_pool_versions
}

output "linux_instance_group_urls" {
  description = "List of GKE generated instance groups for Linux node pools"
  value       = module.gke.linux_instance_group_urls
}

output "windows_node_pool_names" {
  description = "List of Windows node pool names"
  value       = module.gke.windows_node_pool_names
}

output "windows_node_pool_versions" {
  description = "Windows node pool versions by node pool name"
  value       = module.gke.windows_node_pool_versions
}

output "windows_instance_group_urls" {
  description = "List of GKE generated instance groups for Windows node pools"
  value       = module.gke.windows_instance_group_urls
}