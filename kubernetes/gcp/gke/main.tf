data "google_client_config" "current" {}

data "google_project" "project" {}

locals {
  region = var.autopilot || var.regional ? coalesce(var.region, data.google_client_config.current.region) : var.region
  # Autopilot enables them by default, Standard does not
  dns_cache                       = coalesce(var.dns_cache, var.autopilot)
  enable_vertical_pod_autoscaling = coalesce(var.enable_vertical_pod_autoscaling, var.autopilot)
  # Dataplane V2 enforces the network policies itself and conflicts with the Calico add-on
  network_policy = var.datapath_provider == "ADVANCED_DATAPATH" ? false : var.network_policy
  # The upstream module creates a node service account even when one is given, unused then
  create_service_account = var.service_account == ""
  # GKE refuses to create the default node pool empty, even when it is removed right after
  initial_node_count = var.remove_default_node_pool ? max(var.initial_node_count, 1) : var.initial_node_count
  # Keyed by index: the key may be created in the same apply, so its ID is unknown at plan time
  kms_key_ids = { for index, encryption in var.database_encryption : tostring(index) => encryption.key_name if encryption.state == "ENCRYPTED" }
  # The module of the mode, the other one has no instance
  cluster = try(module.standard[0], module.autopilot[0])
}

# GKE service agent, which encrypts the Kubernetes secrets with the KMS key
resource "google_kms_crypto_key_iam_member" "kms" {
  for_each      = local.kms_key_ids
  crypto_key_id = each.value
  member        = "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

# One upstream module per mode, the other one is not created. In both, public or private nodes and control
# plane endpoint are set by enable_private_nodes and enable_private_endpoint
module "standard" {
  count   = var.autopilot ? 0 : 1
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "46.0.0"

  project_id                            = data.google_client_config.current.project
  name                                  = var.name
  network                               = var.network
  subnetwork                            = var.subnetwork
  ip_range_pods                         = var.ip_range_pods
  ip_range_services                     = var.ip_range_services
  region                                = local.region
  regional                              = var.regional
  zones                                 = var.zones
  enable_private_nodes                  = var.enable_private_nodes
  enable_private_endpoint               = var.enable_private_endpoint
  master_ipv4_cidr_block                = var.master_ipv4_cidr_block
  master_global_access_enabled          = var.master_global_access_enabled
  master_authorized_networks            = var.master_authorized_networks
  dns_allow_external_traffic            = var.dns_allow_external_traffic
  deploy_using_private_endpoint         = var.deploy_using_private_endpoint
  deletion_protection                   = var.deletion_protection
  add_cluster_firewall_rules            = var.add_cluster_firewall_rules
  add_master_webhook_firewall_rules     = var.add_master_webhook_firewall_rules
  add_shadow_firewall_rules             = var.add_shadow_firewall_rules
  authenticator_security_group          = var.authenticator_security_group
  cluster_autoscaling                   = var.cluster_autoscaling
  cluster_dns_domain                    = var.cluster_dns_domain
  cluster_dns_provider                  = var.cluster_dns_provider
  cluster_dns_scope                     = var.cluster_dns_scope
  cluster_ipv4_cidr                     = var.cluster_ipv4_cidr
  cluster_resource_labels               = var.cluster_resource_labels
  config_connector                      = var.config_connector
  configure_ip_masq                     = var.configure_ip_masq
  database_encryption                   = var.database_encryption
  datapath_provider                     = var.datapath_provider
  default_max_pods_per_node             = var.default_max_pods_per_node
  description                           = var.description
  disable_default_snat                  = var.disable_default_snat
  disable_legacy_metadata_endpoints     = var.disable_legacy_metadata_endpoints
  dns_cache                             = local.dns_cache
  enable_binary_authorization           = var.enable_binary_authorization
  enable_confidential_nodes             = var.enable_confidential_nodes
  enable_cost_allocation                = var.enable_cost_allocation
  enable_identity_service               = var.enable_identity_service
  enable_intranode_visibility           = var.enable_intranode_visibility
  enable_kubernetes_alpha               = var.enable_kubernetes_alpha
  enable_l4_ilb_subsetting              = var.enable_l4_ilb_subsetting
  enable_network_egress_export          = var.enable_network_egress_export
  enable_resource_consumption_export    = var.enable_resource_consumption_export
  enable_shielded_nodes                 = var.enable_shielded_nodes
  enable_tpu                            = var.enable_tpu
  enable_vertical_pod_autoscaling       = local.enable_vertical_pod_autoscaling
  filestore_csi_driver                  = var.filestore_csi_driver
  firewall_inbound_ports                = var.firewall_inbound_ports
  firewall_priority                     = var.firewall_priority
  gateway_api_channel                   = var.gateway_api_channel
  gce_pd_csi_driver                     = var.gce_pd_csi_driver
  gke_backup_agent_config               = var.gke_backup_agent_config
  grant_registry_access                 = var.grant_registry_access
  horizontal_pod_autoscaling            = var.horizontal_pod_autoscaling
  http_load_balancing                   = var.http_load_balancing
  identity_namespace                    = var.identity_namespace
  initial_node_count                    = local.initial_node_count
  ip_masq_link_local                    = var.ip_masq_link_local
  ip_masq_resync_interval               = var.ip_masq_resync_interval
  issue_client_certificate              = var.issue_client_certificate
  kubernetes_version                    = var.kubernetes_version
  logging_enabled_components            = var.logging_enabled_components
  logging_service                       = var.logging_service
  maintenance_end_time                  = var.maintenance_end_time
  maintenance_exclusions                = var.maintenance_exclusions
  maintenance_recurrence                = var.maintenance_recurrence
  maintenance_start_time                = var.maintenance_start_time
  monitoring_enable_managed_prometheus  = var.monitoring_enable_managed_prometheus
  monitoring_enabled_components         = var.monitoring_enabled_components
  monitoring_service                    = var.monitoring_service
  network_policy                        = local.network_policy
  network_policy_provider               = var.network_policy_provider
  network_project_id                    = var.network_project_id
  node_metadata                         = var.node_metadata
  node_pools                            = var.node_pools
  node_pools_labels                     = var.node_pools_labels
  node_pools_linux_node_configs_sysctls = var.node_pools_linux_node_configs_sysctls
  node_pools_metadata                   = var.node_pools_metadata
  node_pools_oauth_scopes               = var.node_pools_oauth_scopes
  node_pools_resource_labels            = var.node_pools_resource_labels
  node_pools_tags                       = var.node_pools_tags
  node_pools_taints                     = var.node_pools_taints
  non_masquerade_cidrs                  = var.non_masquerade_cidrs
  notification_config_topic             = var.notification_config_topic
  registry_project_ids                  = var.registry_project_ids
  release_channel                       = var.release_channel
  remove_default_node_pool              = var.remove_default_node_pool
  resource_usage_export_dataset_id      = var.resource_usage_export_dataset_id
  create_service_account                = local.create_service_account
  service_account                       = var.service_account
  service_account_name                  = var.service_account_name
  service_external_ips                  = var.service_external_ips
  shadow_firewall_rules_log_config      = var.shadow_firewall_rules_log_config
  shadow_firewall_rules_priority        = var.shadow_firewall_rules_priority
  stub_domains                          = var.stub_domains
  timeouts                              = var.timeouts
  upstream_nameservers                  = var.upstream_nameservers
  windows_node_pools                    = var.windows_node_pools

  depends_on = [google_kms_crypto_key_iam_member.kms]
}

# Autopilot clusters are regional only
module "autopilot" {
  count   = var.autopilot ? 1 : 0
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster"
  version = "46.0.0"

  project_id                         = data.google_client_config.current.project
  name                               = var.name
  network                            = var.network
  subnetwork                         = var.subnetwork
  ip_range_pods                      = var.ip_range_pods
  ip_range_services                  = var.ip_range_services
  region                             = local.region
  regional                           = true
  zones                              = var.zones
  enable_private_nodes               = var.enable_private_nodes
  enable_private_endpoint            = var.enable_private_endpoint
  master_ipv4_cidr_block             = var.master_ipv4_cidr_block
  master_global_access_enabled       = var.master_global_access_enabled
  master_authorized_networks         = var.master_authorized_networks
  dns_allow_external_traffic         = var.dns_allow_external_traffic
  deploy_using_private_endpoint      = var.deploy_using_private_endpoint
  deletion_protection                = var.deletion_protection
  add_cluster_firewall_rules         = var.add_cluster_firewall_rules
  add_master_webhook_firewall_rules  = var.add_master_webhook_firewall_rules
  add_shadow_firewall_rules          = var.add_shadow_firewall_rules
  allow_net_admin                    = var.allow_net_admin
  authenticator_security_group       = var.authenticator_security_group
  cluster_ipv4_cidr                  = var.cluster_ipv4_cidr
  cluster_resource_labels            = var.cluster_resource_labels
  database_encryption                = var.database_encryption
  default_compute_class_enabled      = var.default_compute_class_enabled
  description                        = var.description
  disable_default_snat               = var.disable_default_snat
  dns_cache                          = local.dns_cache
  enable_binary_authorization        = var.enable_binary_authorization
  enable_confidential_nodes          = var.enable_confidential_nodes
  enable_cost_allocation             = var.enable_cost_allocation
  enable_l4_ilb_subsetting           = var.enable_l4_ilb_subsetting
  enable_network_egress_export       = var.enable_network_egress_export
  enable_resource_consumption_export = var.enable_resource_consumption_export
  enable_tpu                         = var.enable_tpu
  enable_vertical_pod_autoscaling    = local.enable_vertical_pod_autoscaling
  filestore_csi_driver               = var.filestore_csi_driver
  firewall_inbound_ports             = var.firewall_inbound_ports
  firewall_priority                  = var.firewall_priority
  gateway_api_channel                = var.gateway_api_channel
  gke_backup_agent_config            = var.gke_backup_agent_config
  grant_registry_access              = var.grant_registry_access
  horizontal_pod_autoscaling         = var.horizontal_pod_autoscaling
  http_load_balancing                = var.http_load_balancing
  identity_namespace                 = var.identity_namespace
  issue_client_certificate           = var.issue_client_certificate
  kubernetes_version                 = var.kubernetes_version
  logging_enabled_components         = var.logging_enabled_components
  maintenance_end_time               = var.maintenance_end_time
  maintenance_exclusions             = var.maintenance_exclusions
  maintenance_recurrence             = var.maintenance_recurrence
  maintenance_start_time             = var.maintenance_start_time
  monitoring_enabled_components      = var.monitoring_enabled_components
  network_project_id                 = var.network_project_id
  network_tags                       = var.network_tags
  notification_config_topic          = var.notification_config_topic
  registry_project_ids               = var.registry_project_ids
  release_channel                    = var.release_channel
  resource_usage_export_dataset_id   = var.resource_usage_export_dataset_id
  service_account_name               = var.service_account_name
  service_external_ips               = var.service_external_ips
  shadow_firewall_rules_log_config   = var.shadow_firewall_rules_log_config
  shadow_firewall_rules_priority     = var.shadow_firewall_rules_priority
  timeouts                           = var.timeouts
  create_service_account             = local.create_service_account
  service_account                    = var.service_account

  depends_on = [google_kms_crypto_key_iam_member.kms]
}

# Standard cluster created before the Autopilot mode
moved {
  from = module.gke
  to   = module.standard[0]
}
