# random string
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

module "simple_vpc" {
  source          = "../../../vpc"
  project         = var.project
  region          = var.region
  name            = "simple-${random_string.suffix.result}"
  private_subnets = ["10.0.0.0/16"]
  public_subnets  = ["10.1.0.0/16"]
}
