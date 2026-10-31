# A check block warns on every plan without failing it; the `deprecated` argument needs Terraform 1.15.
# An assertion must reference the configuration, hence an always-false expression on a required input.
check "deprecated" {
  assert {
    condition     = !can(var.name)
    error_message = "The storage/gcp/memorystore/memcache module is deprecated and will be removed. Google deprecated Memorystore for Memcached."
  }
}

data "google_client_config" "current" {}

resource "google_memcache_instance" "cache" {
  name       = var.name
  node_count = var.node_count
  node_config {
    cpu_count      = var.cpu_count
    memory_size_mb = var.memory_size_mb
  }
  display_name       = var.display_name
  labels             = var.labels
  zones              = var.zones
  authorized_network = var.authorized_network
  memcache_version   = var.memcache_version
  region             = data.google_client_config.current.region
  project            = data.google_client_config.current.project
  dynamic "memcache_parameters" {
    for_each = can(coalesce(var.memcache_parameters)) ? [var.memcache_parameters] : []
    content {
      params = memcache_parameters.value
    }
  }
  dynamic "maintenance_policy" {
    for_each = can(coalesce(var.maintenance_policy)) ? [var.maintenance_policy] : []
    content {
      weekly_maintenance_window {
        day      = maintenance_policy.value["day"]
        duration = maintenance_policy.value["duration"]
        start_time {
          hours   = maintenance_policy.value["start_time"]["hours"]
          minutes = maintenance_policy.value["start_time"]["minutes"]
          seconds = maintenance_policy.value["start_time"]["seconds"]
          nanos   = maintenance_policy.value["start_time"]["nanos"]
        }
      }
    }
  }
  lifecycle {
    precondition {
      condition     = (var.cpu_count / 2) * 1024 <= var.memory_size_mb && var.memory_size_mb <= (var.cpu_count / 2) * 16384
      error_message = "For ${var.cpu_count} vCPU(s) memory per node must be within range [${(var.cpu_count / 2) * 1024}, ${(var.cpu_count / 2) * 16384}] MB."
    }
  }
}
