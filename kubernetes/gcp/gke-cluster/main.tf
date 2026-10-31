data "google_client_config" "current" {}

data "google_project" "project" {}

locals {
  project            = data.google_client_config.current.project
  network_project_id = coalesce(var.network_project_id, local.project)
  # try: a zonal cluster without zones fails on the precondition of the cluster rather than here
  region   = var.regional ? coalesce(var.region, data.google_client_config.current.region) : try(join("-", slice(split("-", var.zones[0]), 0, 2)), null)
  location = var.regional ? local.region : try(var.zones[0], null)
  # The zone of a zonal cluster is not repeated in its node locations
  node_locations = var.regional ? (length(var.zones) > 0 ? var.zones : null) : (length(var.zones) > 1 ? slice(var.zones, 1, length(var.zones)) : null)

  service_account = coalesce(var.service_account, one(google_service_account.nodes[*].email))
  # Keyed by project and role, both known at plan time
  registry_projects = var.grant_registry_access ? distinct(concat([local.project], var.registry_project_ids)) : []
  node_roles = merge(
    { "${local.project} roles/container.defaultNodeServiceAccount" = { project = local.project, role = "roles/container.defaultNodeServiceAccount" } },
    { for project in local.registry_projects : "${project} roles/artifactregistry.reader" => { project = project, role = "roles/artifactregistry.reader" } },
  )
  oauth_scopes      = ["https://www.googleapis.com/auth/cloud-platform"]
  boot_disk_kms_key = try(var.boot_disk_kms_key.id, null)
  nap               = var.autoscaling.node_auto_provisioning
  private_endpoint  = var.control_plane.enable_ip_endpoint && var.control_plane.enable_private_endpoint
}

# Nodes of the cluster, with the roles GKE needs and nothing else
resource "google_service_account" "nodes" {
  count        = var.service_account == null ? 1 : 0
  project      = local.project
  account_id   = coalesce(var.service_account_name, "gke-${trimsuffix(substr(var.name, 0, 20), "-")}-nodes")
  display_name = "Nodes of the GKE cluster ${var.name}"
}

resource "google_project_iam_member" "nodes" {
  for_each = var.service_account == null ? local.node_roles : {}
  project  = each.value.project
  role     = each.value.role
  member   = "serviceAccount:${google_service_account.nodes[0].email}"
}

# GKE service agent, which encrypts the Kubernetes secrets with the KMS key
resource "google_kms_crypto_key_iam_member" "etcd" {
  count         = var.kms_key != null ? 1 : 0
  crypto_key_id = var.kms_key.id
  member        = "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

# Compute Engine service agent, which encrypts the boot disks of the nodes with the KMS key
resource "google_kms_crypto_key_iam_member" "boot_disk" {
  count         = var.boot_disk_kms_key != null ? 1 : 0
  crypto_key_id = var.boot_disk_kms_key.id
  member        = "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
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
  datapath_provider   = "ADVANCED_DATAPATH"
  resource_labels     = var.labels
  deletion_protection = var.deletion_protection
  min_master_version  = var.kubernetes_version == "latest" ? null : var.kubernetes_version
  # Every node pool is a google_container_node_pool: refreshing them twice only costs API calls
  skip_node_pool_refresh = true

  # GKE creates a cluster without a default node pool from 1.36.4-gke.1469000 only, when initial_node_count and
  # node_config are omitted; remove_default_node_pool is deprecated for that. Until every release channel is there:
  # one node, removed right after, run by the node service account rather than the Compute Engine default one.
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
  # (gateway-crds-helm with crds.envoyGateway.enabled=true, then its chart with --skip-crds), once checked that the
  # Gateway API version GKE installs fits the Envoy Gateway release. Two copies of the Gateway API CRDs break both.
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
    advanced_datapath_observability_config {
      enable_metrics = var.observability.dataplane_v2_metrics
      enable_relay   = var.observability.dataplane_v2_relay
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

resource "google_container_node_pool" "pools" {
  for_each       = var.node_pools
  name           = each.key
  project        = local.project
  location       = google_container_cluster.cluster.location
  cluster        = google_container_cluster.cluster.name
  node_locations = each.value.node_locations
  node_count     = each.value.node_count
  # Per zone: with total bounds, the autoscaler brings the pool up to total_min_count from no node
  initial_node_count = each.value.node_count == null ? coalesce(each.value.initial_node_count, each.value.total_min_count != null ? 0 : each.value.min_count) : null
  max_pods_per_node  = each.value.max_pods_per_node
  # The autoscaler moves the node count: reading it from the instance groups only costs API calls
  ignore_node_count_changes = true

  # Bounds per zone, or over all the zones of the pool when the total ones are set: the provider rejects both
  dynamic "autoscaling" {
    for_each = each.value.node_count == null ? [1] : []
    content {
      min_node_count       = each.value.total_min_count == null ? each.value.min_count : null
      max_node_count       = each.value.total_max_count == null ? each.value.max_count : null
      total_min_node_count = each.value.total_min_count
      total_max_node_count = each.value.total_max_count
      location_policy      = each.value.location_policy
    }
  }

  # The nodes of the Dynamic Workload Scheduler (flex-start, queued provisioning) do not support auto-repair
  management {
    auto_repair  = !(each.value.flex_start || each.value.queued_provisioning)
    auto_upgrade = true
  }

  upgrade_settings {
    strategy        = each.value.upgrade.strategy
    max_surge       = each.value.upgrade.strategy == "SURGE" ? each.value.upgrade.max_surge : null
    max_unavailable = each.value.upgrade.strategy == "SURGE" ? each.value.upgrade.max_unavailable : null
    dynamic "blue_green_settings" {
      for_each = each.value.upgrade.strategy == "BLUE_GREEN" ? [each.value.upgrade] : []
      content {
        node_pool_soak_duration = blue_green_settings.value.node_pool_soak_duration
        standard_rollout_policy {
          batch_percentage    = blue_green_settings.value.batch_percentage
          batch_soak_duration = blue_green_settings.value.batch_soak_duration
        }
      }
    }
  }

  dynamic "node_drain_config" {
    for_each = each.value.drain != null ? [each.value.drain] : []
    content {
      grace_termination_duration            = node_drain_config.value.grace_termination_duration
      pdb_timeout_duration                  = node_drain_config.value.pdb_timeout_duration
      respect_pdb_during_node_pool_deletion = node_drain_config.value.respect_pdb_during_node_pool_deletion
    }
  }

  dynamic "network_config" {
    for_each = each.value.pod_range != null || each.value.tier_1_networking ? [1] : []
    content {
      pod_range = each.value.pod_range
      dynamic "network_performance_config" {
        for_each = each.value.tier_1_networking ? [1] : []
        content {
          total_egress_bandwidth_tier = "TIER_1"
        }
      }
    }
  }

  dynamic "placement_policy" {
    for_each = each.value.placement_policy != null ? [1] : []
    content {
      type = each.value.placement_policy
    }
  }

  dynamic "queued_provisioning" {
    for_each = each.value.queued_provisioning ? [1] : []
    content {
      enabled = true
    }
  }

  dynamic "best_effort_provisioning" {
    for_each = each.value.best_effort_min_nodes != null ? [1] : []
    content {
      enabled             = true
      min_provision_nodes = each.value.best_effort_min_nodes
    }
  }

  node_config {
    machine_type      = each.value.machine_type
    image_type        = each.value.image_type
    min_cpu_platform  = each.value.min_cpu_platform
    disk_type         = each.value.disk_type
    disk_size_gb      = each.value.disk_size_gb
    boot_disk_kms_key = local.boot_disk_kms_key
    local_ssd_count   = each.value.local_ssd_count
    spot              = each.value.spot
    flex_start        = each.value.flex_start ? true : null
    max_run_duration  = each.value.max_run_duration
    logging_variant   = each.value.logging_variant
    labels            = each.value.labels
    resource_labels   = merge(var.labels, each.value.resource_labels)
    tags              = each.value.tags
    metadata          = merge(each.value.metadata, { "disable-legacy-endpoints" = "true" })
    service_account   = coalesce(each.value.service_account, local.service_account)
    oauth_scopes      = local.oauth_scopes

    gcfs_config {
      enabled = each.value.image_streaming
    }

    gvnic {
      enabled = each.value.gvnic
    }

    shielded_instance_config {
      enable_secure_boot          = each.value.secure_boot
      enable_integrity_monitoring = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    kubelet_config {
      insecure_kubelet_readonly_port_enabled      = "FALSE"
      cpu_manager_policy                          = each.value.kubelet.cpu_manager_policy
      cpu_cfs_quota                               = each.value.kubelet.cpu_cfs_quota
      cpu_cfs_quota_period                        = each.value.kubelet.cpu_cfs_quota_period
      pod_pids_limit                              = each.value.kubelet.pod_pids_limit
      max_parallel_image_pulls                    = each.value.kubelet.max_parallel_image_pulls
      image_gc_high_threshold_percent             = each.value.kubelet.image_gc_high_threshold_percent
      image_gc_low_threshold_percent              = each.value.kubelet.image_gc_low_threshold_percent
      container_log_max_size                      = each.value.kubelet.container_log_max_size
      container_log_max_files                     = each.value.kubelet.container_log_max_files
      single_process_oom_kill                     = each.value.kubelet.single_process_oom_kill
      shutdown_grace_period_seconds               = each.value.kubelet.shutdown_grace_period_seconds
      shutdown_grace_period_critical_pods_seconds = each.value.kubelet.shutdown_grace_period_critical_pods_seconds
      allowed_unsafe_sysctls                      = each.value.kubelet.allowed_unsafe_sysctls
      dynamic "topology_manager" {
        for_each = each.value.kubelet.topology_manager_policy != null ? [1] : []
        content {
          policy = each.value.kubelet.topology_manager_policy
          scope  = each.value.kubelet.topology_manager_scope
        }
      }
      dynamic "memory_manager" {
        for_each = each.value.kubelet.memory_manager_policy != null ? [1] : []
        content {
          policy = each.value.kubelet.memory_manager_policy
        }
      }
    }

    linux_node_config {
      cgroup_mode                  = each.value.linux.cgroup_mode
      sysctls                      = each.value.linux.sysctls
      transparent_hugepage_enabled = each.value.linux.transparent_hugepage_enabled
      transparent_hugepage_defrag  = each.value.linux.transparent_hugepage_defrag
      dynamic "hugepages_config" {
        for_each = each.value.linux.hugepages_2m != null || each.value.linux.hugepages_1g != null ? [1] : []
        content {
          hugepage_size_2m = each.value.linux.hugepages_2m
          hugepage_size_1g = each.value.linux.hugepages_1g
        }
      }
    }

    dynamic "ephemeral_storage_local_ssd_config" {
      for_each = each.value.ephemeral_local_ssd_count != null ? [1] : []
      content {
        local_ssd_count = each.value.ephemeral_local_ssd_count
      }
    }

    dynamic "local_nvme_ssd_block_config" {
      for_each = each.value.local_nvme_ssd_block_count != null ? [1] : []
      content {
        local_ssd_count = each.value.local_nvme_ssd_block_count
      }
    }

    dynamic "secondary_boot_disks" {
      for_each = each.value.secondary_boot_disks
      content {
        disk_image = secondary_boot_disks.value.disk_image
        mode       = secondary_boot_disks.value.mode
      }
    }

    dynamic "guest_accelerator" {
      for_each = each.value.gpu != null ? [each.value.gpu] : []
      content {
        type               = guest_accelerator.value.type
        count              = guest_accelerator.value.count
        gpu_partition_size = guest_accelerator.value.partition_size
        gpu_driver_installation_config {
          gpu_driver_version = guest_accelerator.value.driver_version
        }
        dynamic "gpu_sharing_config" {
          for_each = guest_accelerator.value.sharing_strategy != null ? [1] : []
          content {
            gpu_sharing_strategy       = guest_accelerator.value.sharing_strategy
            max_shared_clients_per_gpu = guest_accelerator.value.max_shared_clients_per_gpu
          }
        }
      }
    }

    dynamic "advanced_machine_features" {
      for_each = each.value.threads_per_core != null ? [1] : []
      content {
        threads_per_core = each.value.threads_per_core
      }
    }

    dynamic "sandbox_config" {
      for_each = each.value.sandbox ? [1] : []
      content {
        type = "GVISOR"
      }
    }

    dynamic "confidential_nodes" {
      for_each = each.value.confidential_instance_type != null ? [1] : []
      content {
        enabled                    = true
        confidential_instance_type = each.value.confidential_instance_type
      }
    }

    dynamic "reservation_affinity" {
      for_each = each.value.reservation_affinity != null ? [each.value.reservation_affinity] : []
      content {
        consume_reservation_type = reservation_affinity.value.type
        key                      = reservation_affinity.value.key
        values                   = reservation_affinity.value.values
      }
    }

    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

# Same behaviour as the gke module: gcloud writes the credentials of the cluster to the file once created.
# Proposal to discuss: a local_sensitive_file rendered from the cluster outputs (endpoint, CA, exec through
# gke-gcloud-auth-plugin) instead. No gcloud call at apply time, no merge into an existing file, the file follows the
# cluster (deleted on destroy, rewritten when the endpoint changes), at the cost of the hashicorp/local provider.
resource "terraform_data" "kubeconfig" {
  count = can(coalesce(var.kubeconfig_path)) ? 1 : 0
  triggers_replace = [
    abspath(var.kubeconfig_path),
    google_container_cluster.cluster.id,
  ]
  provisioner "local-exec" {
    # The DNS endpoint when it is the only one reachable from outside the VPC, the private one from inside it
    command = join(" ", compact([
      "gcloud container clusters get-credentials ${google_container_cluster.cluster.name}",
      "--location=${google_container_cluster.cluster.location}",
      "--project=${local.project}",
      !var.control_plane.enable_ip_endpoint || (local.private_endpoint && var.control_plane.dns_allow_external_traffic) ? "--dns-endpoint" : (local.private_endpoint ? "--internal-ip" : ""),
    ]))
    environment = {
      KUBECONFIG = abspath(var.kubeconfig_path)
    }
  }
}
