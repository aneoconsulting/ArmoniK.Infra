data "google_client_config" "current" {}

locals {
  project            = data.google_client_config.current.project
  network_project_id = coalesce(var.network_project_id, local.project)
  # try: a zonal cluster without zones fails on the precondition of the cluster
  region   = var.regional ? coalesce(var.region, data.google_client_config.current.region) : try(join("-", slice(split("-", var.zones[0]), 0, 2)), null)
  location = var.regional ? local.region : try(var.zones[0], null)
  # The zone of a zonal cluster is not repeated in its node locations
  node_locations = var.regional ? (length(var.zones) > 0 ? var.zones : null) : (length(var.zones) > 1 ? slice(var.zones, 1, length(var.zones)) : null)

  service_account = coalesce(var.service_account, one(google_service_account.nodes[*].email))
  # Keyed by project and role, both known at plan time
  registry_projects = var.grant_registry_access ? distinct(concat([local.project], var.registry_project_ids)) : []
  node_roles = merge(
    { for role in var.service_account_roles : "${local.project} ${role}" => { project = local.project, role = role } },
    { for project in local.registry_projects : "${project} roles/artifactregistry.reader" => { project = project, role = "roles/artifactregistry.reader" } },
  )
  oauth_scopes      = ["https://www.googleapis.com/auth/cloud-platform"]
  boot_disk_kms_key = try(var.boot_disk_kms_key.id, null)
  nap               = var.autoscaling.node_auto_provisioning
  private_endpoint  = var.control_plane.enable_ip_endpoint && var.control_plane.enable_private_endpoint
}

resource "google_container_cluster" "cluster" {
  name                = var.name
  description         = var.description
  project             = local.project
  location            = local.location
  node_locations      = local.node_locations
  network             = "projects/${local.network_project_id}/global/networks/${var.network}"
  subnetwork          = "projects/${local.network_project_id}/regions/${local.region}/subnetworks/${var.subnetwork}"
  networking_mode     = "VPC_NATIVE"
  datapath_provider   = var.networking.dataplane_v2 ? "ADVANCED_DATAPATH" : "LEGACY_DATAPATH"
  resource_labels     = var.labels
  deletion_protection = var.deletion_protection
  min_master_version  = var.kubernetes_version == "latest" ? null : var.kubernetes_version
  # Every node pool is a google_container_node_pool: refreshing them twice only costs API calls
  skip_node_pool_refresh = true

  # GKE creates a cluster without a default node pool from 1.36.4-gke.1469000 only, when initial_node_count and
  # node_config are omitted; remove_default_node_pool is deprecated for that.
  remove_default_node_pool = true
  initial_node_count       = 1
  node_config {
    service_account = local.service_account
    oauth_scopes    = local.oauth_scopes
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  default_max_pods_per_node                = var.networking.default_max_pods_per_node
  enable_shielded_nodes                    = true
  enable_legacy_abac                       = false
  enable_intranode_visibility              = var.networking.intranode_visibility
  enable_l4_ilb_subsetting                 = var.networking.l4_ilb_subsetting
  enable_fqdn_network_policy               = var.networking.fqdn_network_policy
  enable_cilium_clusterwide_network_policy = var.networking.cilium_clusterwide_network_policy
  # Null rather than disabled when off: the transparent encryption is set only when asked
  in_transit_encryption_config = var.networking.in_transit_encryption ? "IN_TRANSIT_ENCRYPTION_INTER_NODE_TRANSPARENT" : null

  dynamic "network_policy" {
    for_each = var.networking.calico ? [1] : []
    content {
      enabled  = true
      provider = "CALICO"
    }
  }

  release_channel {
    channel = var.release_channel
  }

  dynamic "gke_auto_upgrade_config" {
    for_each = var.maintenance.patch_mode != null ? [1] : []
    content {
      patch_mode = var.maintenance.patch_mode
    }
  }

  dynamic "rollback_safe_upgrade" {
    for_each = var.maintenance.rollback_soak_duration != null ? [1] : []
    content {
      control_plane_soak_duration = var.maintenance.rollback_soak_duration
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.ip_range_pods
    services_secondary_range_name = var.ip_range_services
    dynamic "additional_pod_ranges_config" {
      for_each = length(var.additional_ip_ranges_pods) > 0 ? [1] : []
      content {
        pod_range_names = var.additional_ip_ranges_pods
      }
    }
  }

  default_snat_status {
    disabled = var.networking.disable_default_snat
  }

  dynamic "dns_config" {
    for_each = var.networking.cloud_dns ? [1] : []
    content {
      cluster_dns                   = "CLOUD_DNS"
      cluster_dns_scope             = "CLUSTER_SCOPE"
      cluster_dns_domain            = var.networking.cluster_dns_domain
      additive_vpc_scope_dns_domain = var.networking.additive_vpc_scope_dns_domain
    }
  }

  # GKE owns the Gateway API CRDs of the standard channel. Envoy Gateway then installs its own CRDs only
  # Two copies of the Gateway API CRDs break both.
  gateway_api_config {
    channel = var.networking.gateway_api ? "CHANNEL_STANDARD" : "CHANNEL_DISABLED"
  }

  # spec.externalIPs lets whoever creates a Service intercept the traffic to any IP (CVE-2020-8554), hence off by
  # default as in GKE. LoadBalancer and NodePort Services, and Gateways, do not need it.
  service_external_ips_config {
    enabled = var.networking.service_external_ips
  }

  dynamic "private_cluster_config" {
    for_each = var.networking.enable_private_nodes ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = var.control_plane.enable_ip_endpoint ? var.control_plane.enable_private_endpoint : null
      master_ipv4_cidr_block  = var.control_plane.master_ipv4_cidr_block
      dynamic "master_global_access_config" {
        for_each = local.private_endpoint && var.control_plane.global_access ? [1] : []
        content {
          enabled = true
        }
      }
    }
  }

  # Always set with the IP endpoints: without this block, GKE disables the authorized networks and the public
  # endpoint accepts any IP
  dynamic "master_authorized_networks_config" {
    for_each = var.control_plane.enable_ip_endpoint ? [1] : []
    content {
      gcp_public_cidrs_access_enabled      = false
      private_endpoint_enforcement_enabled = var.control_plane.authorized_networks_on_private_endpoint
      dynamic "cidr_blocks" {
        for_each = var.control_plane.authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = var.control_plane.dns_allow_external_traffic
    }
    ip_endpoints_config {
      enabled = var.control_plane.enable_ip_endpoint
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  anonymous_authentication_config {
    mode = "LIMITED"
  }

  rbac_binding_config {
    enable_insecure_binding_system_authenticated   = false
    enable_insecure_binding_system_unauthenticated = false
  }

  workload_identity_config {
    workload_pool = "${local.project}.svc.id.goog"
  }

  dynamic "database_encryption" {
    for_each = var.kms_key != null ? [var.kms_key.id] : []
    content {
      state    = "ENCRYPTED"
      key_name = database_encryption.value
    }
  }

  security_posture_config {
    mode               = var.security.posture_mode
    vulnerability_mode = var.security.vulnerability_mode
  }

  dynamic "binary_authorization" {
    for_each = var.security.binary_authorization != null ? [1] : []
    content {
      evaluation_mode = var.security.binary_authorization
    }
  }

  dynamic "authenticator_groups_config" {
    for_each = var.security.security_group != null ? [1] : []
    content {
      security_group = var.security.security_group
    }
  }

  identity_service_config {
    enabled = var.security.identity_service
  }

  secret_manager_config {
    enabled = var.security.secret_manager
  }

  dynamic "fleet" {
    for_each = var.fleet_project != null ? [1] : []
    content {
      project = var.fleet_project
    }
  }

  cluster_autoscaling {
    enabled                       = local.nap != null
    autoscaling_profile           = var.autoscaling.profile
    default_compute_class_enabled = var.autoscaling.default_compute_class
    auto_provisioning_locations   = try(local.nap.locations, null)
    dynamic "resource_limits" {
      for_each = local.nap != null ? concat([
        { resource_type = "cpu", minimum = local.nap.min_cpu_cores, maximum = local.nap.max_cpu_cores },
        { resource_type = "memory", minimum = local.nap.min_memory_gb, maximum = local.nap.max_memory_gb },
      ], local.nap.gpu_resources) : []
      content {
        resource_type = resource_limits.value.resource_type
        minimum       = resource_limits.value.minimum
        maximum       = resource_limits.value.maximum
      }
    }
    dynamic "auto_provisioning_defaults" {
      for_each = local.nap != null ? [local.nap] : []
      content {
        service_account   = local.service_account
        oauth_scopes      = local.oauth_scopes
        image_type        = auto_provisioning_defaults.value.image_type
        disk_type         = auto_provisioning_defaults.value.disk_type
        disk_size         = auto_provisioning_defaults.value.disk_size_gb
        min_cpu_platform  = auto_provisioning_defaults.value.min_cpu_platform
        boot_disk_kms_key = local.boot_disk_kms_key
        management {
          auto_repair  = true
          auto_upgrade = true
        }
        shielded_instance_config {
          enable_secure_boot          = true
          enable_integrity_monitoring = true
        }
        upgrade_settings {
          strategy        = "SURGE"
          max_surge       = 1
          max_unavailable = 0
        }
      }
    }
  }

  pod_autoscaling {
    hpa_profile = var.autoscaling.hpa_profile
  }

  # Defaults of every node pool, and settings of the auto-provisioned ones
  node_pool_defaults {
    node_config_defaults {
      insecure_kubelet_readonly_port_enabled = "FALSE"
      logging_variant                        = var.observability.logging_variant
      gcfs_config {
        enabled = true
      }
    }
  }

  node_pool_auto_config {
    node_kubelet_config {
      insecure_kubelet_readonly_port_enabled = "FALSE"
    }
    linux_node_config {
      cgroup_mode = "CGROUP_MODE_V2"
    }
  }

  addons_config {
    http_load_balancing {
      disabled = !var.addons.http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = !var.addons.horizontal_pod_autoscaling
    }
    dns_cache_config {
      enabled = var.networking.dns_cache
    }
    dynamic "network_policy_config" {
      for_each = var.networking.calico ? [1] : []
      content {
        disabled = false
      }
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    gcp_filestore_csi_driver_config {
      enabled = var.addons.filestore_csi_driver
    }
    gcs_fuse_csi_driver_config {
      enabled = var.addons.gcs_fuse_csi_driver
    }
    lustre_csi_driver_config {
      enabled = var.addons.lustre_csi_driver
    }
    gke_backup_agent_config {
      enabled = var.addons.backup_agent
    }
    config_connector_config {
      enabled = var.addons.config_connector
    }
    stateful_ha_config {
      enabled = var.addons.stateful_ha
    }
  }

  vertical_pod_autoscaling {
    enabled = var.addons.vertical_pod_autoscaling
  }

  dynamic "logging_config" {
    for_each = var.observability.logging_components != null ? [1] : []
    content {
      enable_components = var.observability.logging_components
    }
  }

  monitoring_config {
    enable_components = var.observability.monitoring_components
    managed_prometheus {
      enabled = var.observability.managed_prometheus
    }
    dynamic "advanced_datapath_observability_config" {
      for_each = var.networking.dataplane_v2 ? [1] : []
      content {
        enable_metrics = var.observability.dataplane_v2_metrics
        enable_relay   = var.observability.dataplane_v2_relay
      }
    }
  }

  cost_management_config {
    enabled = var.observability.cost_allocation
  }

  dynamic "resource_usage_export_config" {
    for_each = var.observability.usage_export_dataset != null ? [1] : []
    content {
      enable_resource_consumption_metering = true
      enable_network_egress_metering       = var.observability.network_egress_metering
      bigquery_destination {
        dataset_id = var.observability.usage_export_dataset
      }
    }
  }

  dynamic "notification_config" {
    for_each = var.maintenance.notification_topic != null ? [1] : []
    content {
      pubsub {
        enabled = true
        topic   = var.maintenance.notification_topic
      }
    }
  }

  maintenance_policy {
    dynamic "daily_maintenance_window" {
      for_each = var.maintenance.recurrence == null ? [1] : []
      content {
        start_time = var.maintenance.start_time
      }
    }
    dynamic "recurring_window" {
      for_each = var.maintenance.recurrence != null ? [1] : []
      content {
        start_time = var.maintenance.start_time
        end_time   = var.maintenance.end_time
        recurrence = var.maintenance.recurrence
      }
    }
    dynamic "maintenance_exclusion" {
      for_each = var.maintenance.exclusions
      content {
        exclusion_name = maintenance_exclusion.value.name
        start_time     = maintenance_exclusion.value.start_time
        end_time       = maintenance_exclusion.value.end_time
        exclusion_options {
          scope = maintenance_exclusion.value.scope
        }
      }
    }
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }

  lifecycle {
    # The default node pool and its settings only exist during the creation of the cluster
    ignore_changes = [node_pool, node_config, initial_node_count]
    precondition {
      condition     = var.regional || length(var.zones) > 0
      error_message = "\"zones\" must list at least one zone when \"regional\" is false."
    }
    precondition {
      condition     = !local.private_endpoint || var.networking.enable_private_nodes
      error_message = "\"control_plane.enable_private_endpoint\" requires \"networking.enable_private_nodes\"."
    }
    precondition {
      condition     = !var.networking.gateway_api || var.addons.http_load_balancing
      error_message = "\"networking.gateway_api\" requires \"addons.http_load_balancing\": the GKE Gateway controller runs in the HttpLoadBalancing add-on."
    }
    precondition {
      condition = var.networking.dataplane_v2 || !anytrue([
        var.networking.fqdn_network_policy,
        var.networking.cilium_clusterwide_network_policy,
        var.networking.in_transit_encryption,
        var.observability.dataplane_v2_metrics,
        var.observability.dataplane_v2_relay,
      ])
      error_message = "\"networking.fqdn_network_policy\", \"networking.cilium_clusterwide_network_policy\", \"networking.in_transit_encryption\", \"observability.dataplane_v2_metrics\" and \"observability.dataplane_v2_relay\" require \"networking.dataplane_v2\"."
    }
    precondition {
      condition     = length(var.node_pools) > 0 || local.nap != null
      error_message = "Without \"node_pools\", \"autoscaling.node_auto_provisioning\" is required: the Pods that select no ComputeClass (kube-system first) would find no node."
    }
  }

  depends_on = [
    google_kms_crypto_key_iam_member.etcd,
    google_kms_crypto_key_iam_member.boot_disk,
    google_project_iam_member.nodes,
  ]
}

# GKE connects the control plane to a cluster created on 1.29 or later through Private Service Connect, which reaches
# the nodes and Pods on every port: webhooks and aggregated APIs need no firewall rule. A cluster on VPC Network Peering
# (deprecated) only reaches ports 443 and 10250, so the webhooks on other ports (KEDA, cert-manager) time out.
check "control_plane_psc" {
  assert {
    condition     = try(google_container_cluster.cluster.private_cluster_config[0].peering_name, "") == ""
    error_message = "The control plane of the cluster ${var.name} is connected through VPC Network Peering: add a firewall rule from its range to the nodes on the ports of the webhooks (8443, 9443, 15017...)."
  }
}
