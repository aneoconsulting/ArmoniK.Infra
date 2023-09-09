module "vpc" {
  source = "../../../../../networking/gcp/vpc"
  name   = "gke-simple"
  gke_subnet = {
    name                = "gke-simple"
    nodes_cidr_block    = "10.43.0.0/16",
    pods_cidr_block     = "172.16.0.0/16"
    services_cidr_block = "172.17.17.0/24"
    region              = var.region
  }
}

module "gke" {
  source            = "../../../gke"
  name              = "simple"
  network           = module.vpc.name
  ip_range_pods     = module.vpc.gke_subnet_pods_range_name
  ip_range_services = module.vpc.gke_subnet_svc_range_name
  subnetwork        = module.vpc.gke_subnet_name
  subnetwork_cidr   = module.vpc.gke_subnet_cidr_block
  kubeconfig_path   = abspath("${path.root}/generated/kubeconfig")
  autopilot         = true  # default value
  private           = false # public Standard GKE
}
