module "complete_example" {
  source        = "../../../psa"
  vpc_link      = data.google_compute_network.vpc.self_link
  name          = "my-address"
  ip            = "10.132.112.84"
  ip_version    = "IPV4"
  service_name  = "servicenetworking.googleapis.com"
  description   = "Description of global address for complete example"
  prefix_length = 0
  adress_type   = "INTERNAL"
}

data "google_compute_network" "vpc" {
  name = "default"
}
