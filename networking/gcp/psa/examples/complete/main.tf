data "google_compute_network" "vpc" {
  name = "default"
}

module "complete" {
  source        = "../../../psa"
  name          = "complete-psa"
  network       = data.google_compute_network.vpc.self_link
  description   = "Complete example for PSA"
  ip_version    = "IPV4"
  prefix_length = 24
  address_type  = "INTERNAL"
}
