# random string
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

# VPC
module "simple_vpc" {
  source = "../../../vpc"
  name   = "simple-${random_string.suffix.result}"
  subnets = {
    "private-subnet-1" = {
      cidr_block    = "10.0.0.0/16"
      region        = "europe-west9"
      public_access = false
    }
    "public-subnet-1" = {
      cidr_block    = "10.1.0.0/16"
      region        = "europe-west9"
      public_access = true
    }
  }
}
