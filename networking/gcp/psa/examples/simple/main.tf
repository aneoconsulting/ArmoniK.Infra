module "simple_example" {
  source                    = "../../../psa"
  vpc_network               = "my-vpc-network"
  global_adress_name        = "my-adress"
  global_adress_adress      = "10.132.112.84"
  global_address_ip_version = "IPV6"
  global_address_purpose    = "VPC_PEERING"
  service_name              = "my-new-service"
}
