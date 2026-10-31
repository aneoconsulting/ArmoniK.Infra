module "vpc" {
  source = "../../../../../../networking/gcp/vpc"
  name   = "valkey-simple"
  subnets = {
    "valkey-simple-psc" = {
      cidr_block    = "10.44.0.0/28"
      region        = var.region
      public_access = false
    }
  }
  service_connection_policies = {
    memorystore = {
      service_class = "gcp-memorystore"
      subnets       = ["valkey-simple-psc"]
    }
  }
}

module "simple_valkey" {
  source              = "../../../valkey"
  name                = "valkey-simple"
  network             = module.vpc.id
  deletion_protection = false
}
