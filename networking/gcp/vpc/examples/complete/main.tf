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
  source                            = "../../../vpc"
  project                           = var.project
  region                            = var.region
  name                              = "complete-${random_string.suffix.result}"
  gke_name                          = "complete-vpc"
  private_subnets                   = [for k in range(3) : cidrsubnet(local.cidr, 4, k)]
  public_subnets                    = [for k in range(3) : cidrsubnet(local.cidr, 8, k + 48)]
  pod_subnets                       = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
  enable_external_access            = true
  flow_log_max_aggregation_interval = "INTERVAL_30_SEC"
}
