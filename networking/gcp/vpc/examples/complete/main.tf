# random string
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  cidr = "10.0.0.0/16"
}

module "complete_vpc" {
  source                                    = "../../../vpc"
  name                                      = "complete-${random_string.suffix.result}"
  auto_create_subnetworks                   = false
  routing_mode                              = "GLOBAL"
  mtu                                       = 1460
  enable_ula_internal_ipv6                  = false
  internal_ipv6_range                       = null
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
  delete_default_routes_on_create           = true
  shared_vpc_host_project                   = false
  private_subnets                           = [for k in range(3) : cidrsubnet(local.cidr, 4, k)]
  public_subnets                            = [for k in range(3) : cidrsubnet(local.cidr, 8, k + 48)]
  gke_subnets = {
    "gke-alpha" = {
      nodes_cidr_block    = "10.10.0.0/8",
      pods_cidr_block     = "192.168.64.0/22"
      services_cidr_block = "192.168.1.0/24"
    }
  }
  enable_google_access              = true
  flow_log_max_aggregation_interval = "INTERVAL_30_SEC"
}
