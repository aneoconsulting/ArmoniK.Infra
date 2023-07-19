resource "google_redis_instance" "default" {
  #depends_on = [module.enable_apis]  ---> project service

  project            = var.project
  name               = var.name
  tier               = var.tier
  replica_count      = var.tier == "STANDARD_HA" ? var.replica_count : null
  read_replicas_mode = var.tier == "STANDARD_HA" ? var.read_replicas_mode : null
  memory_size_gb     = var.memory_size_gb
  connect_mode       = var.connect_mode

  region                  = var.region
  location_id             = var.location_id
  alternative_location_id = var.alternative_location_id

  authorized_network   = var.authorized_network
  customer_managed_key = var.customer_managed_key

  redis_version      = var.redis_version
  redis_configs      = var.redis_configs
  display_name       = var.display_name
  reserved_ip_range  = var.reserved_ip_range
  secondary_ip_range = var.secondary_ip_range

  labels = var.labels

  auth_enabled = var.auth_enabled

  transit_encryption_mode = var.transit_encryption_mode

  dynamic "maintenance_policy" {
    for_each = var.maintenance_policy != null ? [var.maintenance_policy] : []
    content {
      weekly_maintenance_window {
        day = maintenance_policy.value["day"]
        start_time {
          hours   = maintenance_policy.value["start_time"]["hours"]
          minutes = maintenance_policy.value["start_time"]["minutes"]
          seconds = maintenance_policy.value["start_time"]["seconds"]
          nanos   = maintenance_policy.value["start_time"]["nanos"]
        }
      }
    }
  }

  dynamic "persistence_config" {
    for_each = var.persistence_config != null ? [var.persistence_config] : []
    content {
      persistence_mode        = persistence_config.value["persistence_mode"]
      rdb_snapshot_period     = persistence_config.value["rdb_snapshot_period"]
      rdb_snapshot_start_time = persistence_config.value["rdb_snapshot_start_time"] 
    }
  }

  lifecycle {
    ignore_changes = [maintenance_schedule]
  }
}

locals {
  activate_compute_identity = 0 != length([for i in var.activate_api_identities : i if i.api == "compute.googleapis.com"])
  services                  = var.enable_apis ? toset(concat(var.activate_apis, [for i in var.activate_api_identities : i.api])) : toset([])
  service_identities = flatten([
    for i in var.activate_api_identities : [
      for r in i.roles :
      { api = i.api, role = r }
    ]
  ])
}

/******************************************
  APIs configuration
 *****************************************/
resource "google_project_service" "project_services" {
  for_each                   = local.services
  project                    = var.project
  service                    = each.value
  disable_on_destroy         = var.disable_services_on_destroy
  disable_dependent_services = var.disable_dependent_services
}

# First handle all service identities EXCEPT compute.googleapis.com.
resource "google_project_service_identity" "project_service_identities" {
  for_each = {
    for i in var.activate_api_identities :
    i.api => i
    if i.api != "compute.googleapis.com"
  }

  provider = google-beta
  project  = var.project
  service  = each.value.api
}

# Process the compute.googleapis.com identity separately, if present in the inputs.
data "google_compute_default_service_account" "default" {
  count   = local.activate_compute_identity ? 1 : 0
  project = var.project
}

############ SECTION - PROJECT SERVICE 

locals {
  add_service_roles = merge(
    {
      for si in local.service_identities :
      "${si.api} ${si.role}" => {
        email = google_project_service_identity.project_service_identities[si.api].email
        role  = si.role
      }
      if si.api != "compute.googleapis.com"
    },
    {
      for si in local.service_identities :
      "${si.api} ${si.role}" => {
        email = data.google_compute_default_service_account.default[0].email
        role  = si.role
      }
      if si.api == "compute.googleapis.com"
    }
  )
}

resource "google_project_iam_member" "project_service_identity_roles" {
  for_each = local.add_service_roles

  project = var.project
  role    = each.value.role
  member  = "serviceAccount:${each.value.email}"
}