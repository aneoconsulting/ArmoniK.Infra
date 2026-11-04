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
