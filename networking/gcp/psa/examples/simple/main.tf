data "google_compute_network" "vpc" {
  name = "default"
}

module "simple" {
  source  = "../../../psa"
  name    = "simaple-psa"
  network = data.google_compute_network.vpc.self_link
}
