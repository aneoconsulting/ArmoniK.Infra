module "simple_example" {
  source                    = "../../../psa"
  vpc_link                  = data.google_compute_network.vpc.self_link
  global_address_name       = "my-address"
  global_address_ip         = "10.132.112.84"
  global_address_ip_version = "IPV6"
}

data "google_compute_network" "vpc" {
  name = "default"
}
