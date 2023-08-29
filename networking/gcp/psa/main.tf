resource "google_compute_global_address" "private_ip_alloc" {
  name          = var.global_address_name
  description   = var.global_address_description
  purpose       = "VPC_PEERING"
  address       = var.global_address_ip
  prefix_length = var.global_address_prefix_length
  ip_version    = var.global_address_ip_version
  address_type  = var.global_address_adress_type
  network       = var.vpc_self_link
}

# Creates the peering with the producer network.
resource "google_service_networking_connection" "private_service_access" {
  network                 = var.vpc_self_link
  service                 = var.service_name
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}
