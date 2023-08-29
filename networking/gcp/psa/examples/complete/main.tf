module "complete_example" {
  source                       = "../../../psa"
  vpc_link                     = data.google_compute_network.vpc.self_link
  global_address_name          = "my-address"
  global_address_ip            = "10.132.112.84"
  global_address_ip_version    = "IPV6"
  service_name                 = "servicenetworking.googleapis.com"
  global_address_description   = "Description of global address for complete example"
  global_address_prefix_length = 0
  global_address_adress_type   = "EXTERNAL"
}

data "google_compute_network" "vpc" {
  name = "default"
}

