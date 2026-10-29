data "google_client_config" "current" {}

data "google_project" "project" {}

locals {
  project            = data.google_client_config.current.project
  network_project_id = coalesce(var.network_project_id, local.project)
  # Autopilot clusters are regional only
  regional = var.autopilot || var.regional
  region   = local.regional ? coalesce(var.region, data.google_client_config.current.region) : join("-", slice(split("-", var.zones[0]), 0, 2))
  location = local.regional ? local.region : var.zones[0]
  # The zone of a zonal cluster is not repeated in its node locations
  node_locations = local.regional ? (length(var.zones) > 0 ? var.zones : null) : (length(var.zones) > 1 ? slice(var.zones, 1, length(var.zones)) : null)
  node_pools     = var.autopilot ? {} : coalesce(var.node_pools, { "default-node-pool" = {} })

  service_account = coalesce(var.service_account, one(google_service_account.nodes[*].email))
  node_roles      = concat(["roles/container.defaultNodeServiceAccount"], var.grant_registry_access ? ["roles/artifactregistry.reader"] : [])
  oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
}

# Nodes of the cluster, with the roles GKE needs and nothing else
resource "google_service_account" "nodes" {
  count        = var.service_account == null ? 1 : 0
  project      = local.project
  account_id   = "gke-${trimsuffix(substr(var.name, 0, 20), "-")}-nodes"
  display_name = "Nodes of the GKE cluster ${var.name}"
}

resource "google_project_iam_member" "nodes" {
  for_each = var.service_account == null ? toset(local.node_roles) : toset([])
  project  = local.project
  role     = each.value
  member   = "serviceAccount:${google_service_account.nodes[0].email}"
}

# GKE service agent, which encrypts the Kubernetes secrets with the KMS key
resource "google_kms_crypto_key_iam_member" "kms" {
  count         = var.kms_key != null ? 1 : 0
  crypto_key_id = var.kms_key.id
  member        = "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

# One cluster for both modes: the Standard-only arguments are null, or their block absent, on Autopilot
resource "google_container_cluster" "cluster" {
  name                = var.name
  description         = var.description
  project             = local.project
  location            = local.location
  node_locations      = local.node_locations
  network             = "projects/${local.network_project_id}/global/networks/${var.network}"
  subnetwork          = "projects/${local.network_project_id}/regions/${local.region}/subnetworks/${var.subnetwork}"
  networking_mode     = "VPC_NATIVE"
  resource_labels     = var.labels
  deletion_protection = var.deletion_protection
  # Null rather than false on Standard: the provider counts any value as set, and enable_autopilot conflicts
  # with the Standard-only arguments below
  enable_autopilot   = var.autopilot ? true : null
  min_master_version = var.kubernetes_version == "latest" ? null : var.kubernetes_version

  # Standard only. GKE cannot create a cluster without its default node pool: one node, removed right after,
  # run by the node service account rather than the Compute Engine default one
  remove_default_node_pool  = var.autopilot ? null : true
  initial_node_count        = var.autopilot ? null : 1
  datapath_provider         = var.autopilot ? null : var.datapath_provider
  default_max_pods_per_node = var.autopilot ? null : var.default_max_pods_per_node
  enable_shielded_nodes     = var.autopilot ? null : true
  dynamic "node_config" {
    for_each = var.autopilot ? [] : [1]
    content {
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
  }

  # Autopilot only: the nodes GKE creates run as the node service account
  dynamic "cluster_autoscaling" {
    for_each = var.autopilot ? [1] : []
    content {
      auto_provisioning_defaults {
        service_account = local.service_account
      }
    }
  }

  release_channel {
    channel = var.release_channel
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.ip_range_pods
    services_secondary_range_name = var.ip_range_services
  }

  default_snat_status {
    disabled = var.disable_default_snat
  }

  dynamic "private_cluster_config" {
    for_each = var.enable_private_nodes ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = var.enable_private_endpoint
      master_ipv4_cidr_block  = var.master_ipv4_cidr_block
      dynamic "master_global_access_config" {
        for_each = var.enable_private_endpoint && var.master_global_access_enabled ? [1] : []
        content {
          enabled = true
        }
      }
    }
  }

  # Always set: without this block, GKE disables the authorized networks and the public endpoint accepts any IP
  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = false
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = var.dns_allow_external_traffic
    }
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
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

  addons_config {
    http_load_balancing {
      disabled = !var.http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = !var.horizontal_pod_autoscaling
    }
    # Standard only, always on with Autopilot
    dynamic "dns_cache_config" {
      for_each = var.autopilot ? [] : [1]
      content {
        enabled = var.dns_cache
      }
    }
    dynamic "gce_persistent_disk_csi_driver_config" {
      for_each = var.autopilot ? [] : [1]
      content {
        enabled = true
      }
    }
  }

  # Always on with Autopilot
  vertical_pod_autoscaling {
    enabled = var.autopilot || var.enable_vertical_pod_autoscaling
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
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }

  lifecycle {
    # The default node pool and its settings only exist during the creation of a Standard cluster
    ignore_changes = [node_pool, node_config, initial_node_count]
  }

  depends_on = [google_kms_crypto_key_iam_member.kms, google_project_iam_member.nodes]
}

# Standard only
resource "google_container_node_pool" "pools" {
  for_each           = local.node_pools
  name               = each.key
  project            = local.project
  location           = google_container_cluster.cluster.location
  cluster            = google_container_cluster.cluster.name
  node_locations     = each.value.node_locations
  initial_node_count = coalesce(each.value.initial_node_count, each.value.min_count)
  max_pods_per_node  = each.value.max_pods_per_node

  autoscaling {
    min_node_count  = each.value.min_count
    max_node_count  = each.value.max_count
    location_policy = each.value.location_policy
  }

  # A release channel requires both
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = each.value.machine_type
    image_type      = each.value.image_type
    disk_size_gb    = each.value.disk_size_gb
    disk_type       = each.value.disk_type
    spot            = each.value.spot
    labels          = each.value.labels
    resource_labels = merge(var.labels, each.value.resource_labels)
    tags            = each.value.tags
    service_account = local.service_account
    oauth_scopes    = local.oauth_scopes
    metadata = {
      "disable-legacy-endpoints" = "true"
    }
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
    workload_metadata_config {
      mode = "GKE_METADATA"
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
    # The autoscaler moves the node count
    ignore_changes = [initial_node_count]
  }
}
