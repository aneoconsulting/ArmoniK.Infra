module "vpc" {
  source = "../../../../../../networking/gcp/vpc"
  name   = "valkey-simple"
  subnets = {
    "valkey-simple-psc" = {
      cidr_block = "10.44.0.0/28"
      region     = var.region
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
  # The endpoints are only created where a service connection policy exists
  depends_on = [module.vpc]
}
