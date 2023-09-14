data "google_client_config" "current" {}

locals {
  prefix_length = !can(coalesce(var.address)) ? coalesce(var.prefix_length, 24) : null
}

resource "google_compute_global_address" "reserved_service_range" {
  name          = var.name
  address       = var.address
  description   = var.description
  ip_version    = var.ip_version
  prefix_length = local.prefix_length
  address_type  = var.address_type
  purpose       = "VPC_PEERING"
  network       = var.network
  project       = data.google_client_config.current.project
}

resource "google_service_networking_connection" "private_service_connection" {
  network                 = var.network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.reserved_service_range.name]
}
