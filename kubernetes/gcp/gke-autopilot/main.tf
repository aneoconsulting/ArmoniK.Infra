data "google_client_config" "current" {}

data "google_project" "project" {}

locals {
  region = coalesce(var.region, data.google_client_config.current.region)
  # The upstream module creates a node service account even when one is given, unused then
  create_service_account = var.service_account == ""
  # Keyed by index: the key may be created in the same apply, so its ID is unknown at plan time
  kms_key_ids = { for index, encryption in var.database_encryption : tostring(index) => encryption.key_name if encryption.state == "ENCRYPTED" }
}

# GKE service agent, which encrypts the Kubernetes secrets with the KMS key
resource "google_kms_crypto_key_iam_member" "kms" {
  for_each      = local.kms_key_ids
  crypto_key_id = each.value
  member        = "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

# Autopilot clusters are regional only. Public or private nodes and control plane endpoint are set by
# enable_private_nodes and enable_private_endpoint
module "gke" {
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
  dns_cache                          = var.dns_cache
  enable_binary_authorization        = var.enable_binary_authorization
  enable_confidential_nodes          = var.enable_confidential_nodes
  enable_cost_allocation             = var.enable_cost_allocation
  enable_l4_ilb_subsetting           = var.enable_l4_ilb_subsetting
  enable_network_egress_export       = var.enable_network_egress_export
  enable_resource_consumption_export = var.enable_resource_consumption_export
  enable_tpu                         = var.enable_tpu
  enable_vertical_pod_autoscaling    = var.enable_vertical_pod_autoscaling
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
