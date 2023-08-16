data "google_client_config" "current" {}

data "google_compute_network" "peering_network" {
  name    = var.vpc_network
  project = data.google_client_config.current.project
}

resource "google_compute_global_address" "private_ip_alloc" {
  project       = data.google_client_config.current.project
  name          = var.global_adress_name
  description   = var.description
  purpose       = var.purpose
  address       = var.address
  prefix_length = var.prefix_length
  ip_version    = var.ip_version
  labels        = var.labels
  address_type  = var.address_type
  network       = data.google_compute_network.peering_network.id
}

# Creates the peering with the producer network.
resource "google_service_networking_connection" "private_service_access" {
  network                 = data.google_compute_network.peering_network.id
  service                 = var.service_name
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}
