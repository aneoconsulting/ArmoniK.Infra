data "google_compute_network" "vpc" {
  name = "default"
}

resource "google_compute_global_address" "service_range" {
  provider      = google-beta
  name          = "simple-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_service_connection" {
  provider      = google-beta
  network                 = data.google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.service_range.name]
}

module "simple_memorystore_for_mecached_instance" {
  source             = "../../../memcache"
  name               = "simple-memcache-test"
  cpu_count          = 2
  memory_size_mb     = 1024
  node_count         = 1
  authorized_network = google_service_networking_connection.private_service_connection.network
}
