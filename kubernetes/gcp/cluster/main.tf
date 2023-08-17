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

resource "null_resource" "update_kubeconfig" {
   provisioner "local-exec" {
   command = "export KUBECONFIG=${var.kubeconfig_path} && gcloud container clusters get-credentials ${module.gke.name} --location=${module.gke.location}"
   
}
}

data "google_client_config" "current" {}
module "gke" {
  source                                = "terraform-google-modules/kubernetes-engine/google"
  project_id                            = var.project_id
  name                                  = var.name
  description                           = var.description
  regional                              = var.regional
  region                                = var.region
  zones                                 = var.zones
  network                               = var.network
  network_project_id                    = var.network_project_id
  subnetwork                            = var.subnetwork
  kubernetes_version                    = var.kubernetes_version
  master_authorized_networks            = var.master_authorized_networks
  enable_vertical_pod_autoscaling       = var.enable_vertical_pod_autoscaling
  horizontal_pod_autoscaling            = var.horizontal_pod_autoscaling
  http_load_balancing                   = var.http_load_balancing
  service_external_ips                  = var.service_external_ips
  datapath_provider                     = var.datapath_provider
  maintenance_start_time                = var.maintenance_start_time
  maintenance_exclusions                = var.maintenance_exclusions
  maintenance_end_time                  = var.maintenance_end_time
  maintenance_recurrence                = var.maintenance_recurrence
  ip_range_pods                         = var.ip_range_pods
  ip_range_services                     = var.ip_range_services
  windows_node_pools                    = var.windows_node_pools
  node_pools_labels                     = var.node_pools_labels
  node_pools_resource_labels            = var.node_pools_resource_labels
  node_pools_metadata                   = var.node_pools_metadata
  node_pools_linux_node_configs_sysctls = var.node_pools_linux_node_configs_sysctls
  enable_cost_allocation                = var.enable_cost_allocation
  resource_usage_export_dataset_id      = var.resource_usage_export_dataset_id
  enable_network_egress_export          = var.enable_network_egress_export
  enable_resource_consumption_export    = var.enable_resource_consumption_export
  cluster_autoscaling                   = var.cluster_autoscaling
  node_pools_taints                     = var.node_pools_taints
  node_pools_tags                       = var.node_pools_tags
  node_pools_oauth_scopes               = var.node_pools_oauth_scopes
  stub_domains                          = var.stub_domains
  upstream_nameservers                  = var.upstream_nameservers
  non_masquerade_cidrs                  = var.non_masquerade_cidrs
  ip_masq_resync_interval               = var.ip_masq_resync_interval
  ip_masq_link_local                    = var.ip_masq_link_local
  configure_ip_masq                     = var.configure_ip_masq
  logging_service                       = var.logging_service
  monitoring_service                    = var.monitoring_service
  create_service_account                = var.create_service_account
  grant_registry_access                 = var.grant_registry_access
  registry_project_ids                  = var.registry_project_ids
  service_account                       = var.service_account
  service_account_name                  = var.service_account_name
  issue_client_certificate              = var.issue_client_certificate
  cluster_ipv4_cidr                     = var.cluster_ipv4_cidr
  cluster_resource_labels               = var.cluster_resource_labels
  dns_cache                             = var.dns_cache
  authenticator_security_group          = var.authenticator_security_group
  identity_namespace                    = var.identity_namespace
  release_channel                       = var.release_channel
  gateway_api_channel                   = var.gateway_api_channel
  add_cluster_firewall_rules            = var.add_cluster_firewall_rules
  add_master_webhook_firewall_rules     = var.add_master_webhook_firewall_rules
  firewall_priority                     = var.firewall_priority
  firewall_inbound_ports                = var.firewall_inbound_ports
  add_shadow_firewall_rules             = var.add_shadow_firewall_rules
  shadow_firewall_rules_priority        = var.shadow_firewall_rules_priority
  shadow_firewall_rules_log_config      = var.shadow_firewall_rules_log_config
  disable_default_snat                  = var.disable_default_snat
  notification_config_topic             = var.notification_config_topic
  network_policy                        = var.network_policy
  network_policy_provider               = var.network_policy_provider
  initial_node_count                    = var.initial_node_count
  remove_default_node_pool              = var.remove_default_node_pool
  filestore_csi_driver                  = var.filestore_csi_driver
  disable_legacy_metadata_endpoints     = var.disable_legacy_metadata_endpoints
  default_max_pods_per_node             = var.default_max_pods_per_node
  database_encryption                   = var.database_encryption
  enable_shielded_nodes                 = var.enable_shielded_nodes
  enable_binary_authorization           = var.enable_binary_authorization
  node_metadata                         = var.node_metadata
  cluster_dns_provider                  = var.cluster_dns_provider
  cluster_dns_scope                     = var.cluster_dns_scope
  cluster_dns_domain                    = var.cluster_dns_domain
  gce_pd_csi_driver                     = var.gce_pd_csi_driver
  gke_backup_agent_config               = var.gke_backup_agent_config
  timeouts                              = var.timeouts
  monitoring_enable_managed_prometheus  = var.monitoring_enable_managed_prometheus
  monitoring_enabled_components         = var.monitoring_enabled_components
  logging_enabled_components            = var.logging_enabled_components
  enable_kubernetes_alpha               = var.enable_kubernetes_alpha
}