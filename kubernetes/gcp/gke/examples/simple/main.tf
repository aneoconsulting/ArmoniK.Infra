module "vpc" {
  source = "../../../../../networking/gcp/vpc"
  name   = "gke-simple"
  gke_subnet = {
    name                = "gke-simple"
    nodes_cidr_block    = "10.43.0.0/16"
    pods_cidr_block     = "172.16.0.0/16"
    services_cidr_block = "172.17.17.0/24"
    region              = var.region
  }
}

# Zonal cluster with the default node pool settings
module "simple_gke" {
  source              = "../../../gke"
  name                = "gke-simple"
  network             = module.vpc.name
  subnetwork          = module.vpc.gke_subnet_name
  ip_range_pods       = module.vpc.gke_subnet_pods_range_name
  ip_range_services   = module.vpc.gke_subnet_svc_range_name
  regional            = false
  zones               = ["${var.region}-a"]
  deletion_protection = false
}
