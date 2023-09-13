data "google_client_config" "current" {}

data "google_container_cluster" "cluster" {
  name = var.cluster_name
}

locals {
  location = data.google_container_cluster.cluster.location
  regional = length(split("-", local.location)) == 2
  # When a release channel is used, node auto-upgrade is enabled and cannot be disabled.
  default_auto_upgrade = local.regional || var.release_channel != "UNSPECIFIED"
}

resource "google_container_node_pool" "pools" {
  for_each = var.node_pools
  name     = each.key
  project  = data.google_client_config.current.project
  location = local.location
  cluster  = var.cluster_name
  # use node_locations if provided, defaults to cluster level node_locations if not specified
  node_locations     = can(coalesce(each.value.node_locations)) ? split(",", each.value.node_locations) : null
  version            = try(each.value.auto_upgrade, local.default_auto_upgrade) ? "" : try(each.value.version, var.min_master_version)
  initial_node_count = can(coalesce(each.value.autoscaling)) ? coalesce(each.value.initial_node_count, each.value.min_count, 0) : null
  max_pods_per_node  = try(each.value.max_pods_per_node, null)
  node_count         = can(coalesce(each.value.autoscaling)) ? null : try(each.value.node_count, 0)
  management {
    auto_repair  = try(each.value.auto_repair, true)
    auto_upgrade = try(each.value.auto_upgrade, local.default_auto_upgrade)
  }
  upgrade_settings {
    strategy        = try(each.value.strategy, "SURGE")
    max_surge       = try(each.value.strategy, "SURGE") == "SURGE" ? try(each.value.max_surge, 1) : null
    max_unavailable = try(each.value.strategy, "SURGE") == "SURGE" ? try(each.value.max_unavailable, 0) : null
    dynamic "blue_green_settings" {
      for_each = try(each.value.strategy, "SURGE") == "BLUE_GREEN" ? [1] : []
      content {
        node_pool_soak_duration = try(each.value.node_pool_soak_duration, null)
        standard_rollout_policy {
          batch_soak_duration = try(each.value.batch_soak_duration, null)
          batch_percentage    = try(each.value.batch_percentage, null)
          batch_node_count    = try(each.value.batch_node_count, null)
        }
      }
    }
  }
  node_config {
    boot_disk_kms_key = try(each.value.boot_disk_kms_key, "")
    image_type        = try(each.value.image_type, "COS_CONTAINERD")
    machine_type      = try(each.value.machine_type, "e2-medium")
    min_cpu_platform  = try(each.value.min_cpu_platform, "")
    local_ssd_count   = try(each.value.local_ssd_count, 0)
    disk_size_gb      = try(each.value.disk_size_gb, 100)
    disk_type         = try(each.value.disk_type, "pd-standard")
    preemptible       = try(each.value.preemptible, false)
    spot              = try(each.value.spot, false)
    service_account   = try(each.value.service_account, var.service_account)
    oauth_scopes      = setunion(var.base_oauth_scopes, try(each.value.oauth_scopes, []))
    tags              = setunion(var.base_tags, try(each.value.tags, []))
    labels            = merge(var.base_labels, try(each.value.labels, {}))
    resource_labels   = merge(var.base_resource_labels, try(each.value.resource_labels, {}))
    metadata = merge(var.base_metadata, try(each.value.metadata, {}), {
      "disable-legacy-endpoints" = var.disable_legacy_metadata_endpoints
    })
    workload_metadata_config {
      mode = try(each.value.node_metadata, var.node_metadata)
    }
    shielded_instance_config {
      enable_secure_boot          = try(each.value.enable_secure_boot, false)
      enable_integrity_monitoring = try(each.value.enable_integrity_monitoring, true)
    }
    dynamic "gcfs_config" {
      for_each = try(each.value.enable_gcfs, false) ? [true] : []
      content {
        enabled = gcfs_config.value
      }
    }
    dynamic "gvnic" {
      for_each = try(each.value.enable_gvnic, false) ? [true] : []
      content {
        enabled = gvnic.value
      }
    }
    dynamic "taint" {
      for_each = merge(var.base_taints, try(each.value.taint, {}))
      content {
        key    = taint.key
        effect = taint.value.effect
        value  = taint.value.value
      }
    }
    dynamic "guest_accelerator" {
      for_each = try(each.value.accelerator_count, 0) > 0 ? [1] : []
      content {
        type               = try(each.value.accelerator_type, "")
        count              = try(each.value.accelerator_count, 0)
        gpu_partition_size = try(each.value.gpu_partition_size, null)
      }
    }
    dynamic "linux_node_config" {
      for_each = try(each.value.linux_node_config, [])
      content {
        sysctls = linux_node_config.value
      }
    }
  }
  lifecycle {
    ignore_changes = [initial_node_count]
  }
  timeouts {
    create = try(var.timeouts.create, "45m")
    update = try(var.timeouts.update, "45m")
    delete = try(var.timeouts.delete, "45m")
  }
  dynamic "autoscaling" {
    for_each = can(coalesce(each.value.autoscaling)) ? [each.value] : []
    content {
      min_node_count       = try(autoscaling["min_node_count"], 0)
      max_node_count       = try(autoscaling["max_node_count"], autoscaling["min_node_count"], 0)
      location_policy      = try(autoscaling["location_policy"], null)
      total_min_node_count = try(autoscaling["total_min_node_count"], null)
      total_max_node_count = try(autoscaling["total_max_node_count"], null)
    }
  }
}

resource "google_container_node_pool" "windows_pools" {
  for_each = var.windows_node_pools
  name     = each.key
  project  = data.google_client_config.current.project
  location = local.location
  cluster  = var.cluster_name
  # use node_locations if provided, defaults to cluster level node_locations if not specified
  node_locations     = can(each.value.node_locations) ? split(",", each.value.node_locations) : null
  version            = try(each.value.auto_upgrade, local.default_auto_upgrade) ? "" : try(each.value.version, var.min_master_version)
  initial_node_count = can(coalesce(each.value.autoscaling)) ? coalesce(each.value.initial_node_count, each.value.min_count, 0) : null
  max_pods_per_node  = try(each.value.max_pods_per_node, null)
  node_count         = can(coalesce(each.value.autoscaling)) ? null : try(each.value.node_count, 0)
  management {
    auto_repair  = try(each.value.auto_repair, true)
    auto_upgrade = try(each.value.auto_upgrade, local.default_auto_upgrade)
  }
  upgrade_settings {
    strategy        = try(each.value.strategy, "SURGE")
    max_surge       = try(each.value.strategy, "SURGE") == "SURGE" ? try(each.value.max_surge, 1) : null
    max_unavailable = try(each.value.strategy, "SURGE") == "SURGE" ? try(each.value.max_unavailable, 0) : null
    dynamic "blue_green_settings" {
      for_each = try(each.value.strategy, "SURGE") == "BLUE_GREEN" ? [1] : []
      content {
        node_pool_soak_duration = try(each.value.node_pool_soak_duration, null)
        standard_rollout_policy {
          batch_soak_duration = try(each.value.batch_soak_duration, null)
          batch_percentage    = try(each.value.batch_percentage, null)
          batch_node_count    = try(each.value.batch_node_count, null)
        }
      }
    }
  }
  node_config {
    boot_disk_kms_key = try(each.value.boot_disk_kms_key, "")
    image_type        = try(each.value.image_type, "COS_CONTAINERD")
    machine_type      = try(each.value.machine_type, "e2-medium")
    min_cpu_platform  = try(each.value.min_cpu_platform, "")
    local_ssd_count   = try(each.value.local_ssd_count, 0)
    disk_size_gb      = try(each.value.disk_size_gb, 100)
    disk_type         = try(each.value.disk_type, "pd-standard")
    preemptible       = try(each.value.preemptible, false)
    spot              = try(each.value.spot, false)
    service_account   = try(each.value.service_account, var.service_account)
    oauth_scopes      = concat(var.base_oauth_scopes, try(each.value.oauth_scopes, []))
    tags              = concat(var.base_tags, try(each.value.tags, []))
    labels            = merge(var.base_labels, try(each.value.labels, {}))
    resource_labels   = merge(var.base_resource_labels, try(each.value.resource_labels, {}))
    metadata = merge(var.base_metadata, try(each.value.metadata, {}), {
      "disable-legacy-endpoints" = var.disable_legacy_metadata_endpoints
    })
    workload_metadata_config {
      mode = try(each.value.node_metadata, var.node_metadata)
    }
    shielded_instance_config {
      enable_secure_boot          = try(each.value.enable_secure_boot, false)
      enable_integrity_monitoring = try(each.value.enable_integrity_monitoring, true)
    }
    dynamic "gcfs_config" {
      for_each = try(each.value.enable_gcfs, false) ? [true] : []
      content {
        enabled = gcfs_config.value
      }
    }
    dynamic "gvnic" {
      for_each = try(each.value.enable_gvnic, false) ? [true] : []
      content {
        enabled = gvnic.value
      }
    }
    dynamic "taint" {
      for_each = merge(var.base_taints, try(each.value.taint, {}))
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }
    dynamic "guest_accelerator" {
      for_each = try(each.value.accelerator_count, 0) > 0 ? [1] : []
      content {
        type               = try(each.value.accelerator_type, "")
        count              = try(each.value.accelerator_count, 0)
        gpu_partition_size = try(each.value.gpu_partition_size, null)
      }
    }
  }
  lifecycle {
    ignore_changes = [initial_node_count]
  }
  timeouts {
    create = try(var.timeouts.create, "45m")
    update = try(var.timeouts.update, "45m")
    delete = try(var.timeouts.delete, "45m")
  }
  dynamic "autoscaling" {
    for_each = can(coalesce(each.value.autoscaling)) ? [each.value] : []
    content {
      min_node_count       = try(autoscaling["min_node_count"], 0)
      max_node_count       = try(autoscaling["max_node_count"], autoscaling["min_node_count"], 0)
      location_policy      = try(autoscaling["location_policy"], null)
      total_min_node_count = try(autoscaling["total_min_node_count"], null)
      total_max_node_count = try(autoscaling["total_max_node_count"], null)
    }
  }
}
