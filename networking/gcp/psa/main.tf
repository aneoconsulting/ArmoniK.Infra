resource "google_compute_global_address" "private_ip_alloc" {
  name          = var.name
  description   = var.description
  purpose       = "VPC_PEERING"
  address       = var.ip
  prefix_length = var.prefix_length
  ip_version    = var.ip_version
  address_type  = var.adress_type
  network       = var.vpc_link
}

# Creates the peering with the producer network.
resource "google_service_networking_connection" "private_service_access" {
  network                 = var.vpc_link
  service                 = var.service_name
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}
