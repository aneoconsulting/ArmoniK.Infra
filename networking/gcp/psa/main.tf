data "google_client_config" "current" {}

data "google_compute_network" "peering_network" {
  name    = var.vpc_network
  project = data.google_client_config.current.project
}

resource "google_compute_global_address" "private_ip_alloc" {
  project       = data.google_client_config.current.project
  name          = var.global_address_name
  description   = var.global_address_description
  purpose       = var.global_address_purpose
  address       = var.global_address_ip
  prefix_length = var.global_address_prefix_length
  ip_version    = var.global_address_ip_version
  address_type  = var.global_address_adress_type
  network       = data.google_compute_network.peering_network.self_link
}

# Creates the peering with the producer network.
resource "google_service_networking_connection" "private_service_access" {
  network                 = data.google_compute_network.peering_network.self_link
  service                 = var.service_name
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}
