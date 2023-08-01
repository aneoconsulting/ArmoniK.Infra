# random string
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  cidr = "10.0.0.0/8"
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
  subnets = merge(
    {
      for k in range(3) :
      "private-subnet-${k}" => {
        cidr_block    = cidrsubnet(local.cidr, 4, k)
        region        = "europe-west${k + 1}"
        public_access = false
      }
    },
    {
      for k in range(3) :
      "public-subnet-${k}" => {
        cidr_block    = cidrsubnet(local.cidr, 8, k + 48)
        region        = "europe-west${k % 2 + 1}"
        public_access = true
    }
    }
  )
  gke_subnets = {
    "gke-alpha" = {
      nodes_cidr_block    = "10.51.0.0/16",
      pods_cidr_block     = "192.168.64.0/22"
      services_cidr_block = "192.168.1.0/24"
      region              = "europe-west9"
    }
  }
  enable_google_access              = true
  flow_log_max_aggregation_interval = "INTERVAL_30_SEC"
}
