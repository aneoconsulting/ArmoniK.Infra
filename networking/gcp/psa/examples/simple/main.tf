module "simple_example" {
  source                    = "../../../psa"
  vpc_network               = data.google_compute_network.vpc.name
  global_address_name       = "my-address"
  global_address_ip         = "10.132.112.84"
  global_address_ip_version = "IPV6"
  global_address_purpose    = "VPC_PEERING"
  service_name              = "servicenetworking.googleapis.com"
}

data "google_compute_network" "vpc" {
  name = "default"
}
