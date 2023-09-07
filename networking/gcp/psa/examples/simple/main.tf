module "simple_example" {
  source     = "../../../psa"
  vpc_link   = data.google_compute_network.vpc.self_link
  name       = "my-address"
  ip         = "10.132.112.84"
  ip_version = "IPV4"
}

data "google_compute_network" "vpc" {
  name = "default"
}
