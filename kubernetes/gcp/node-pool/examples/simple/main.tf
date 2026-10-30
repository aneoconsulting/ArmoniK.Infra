data "google_client_config" "current" {}

module "vpc" {
  source = "../../../../../networking/gcp/vpc"
  name   = "simple-gke-node-pool"
  gke_subnet = {
    name                = "simple-gke-node-pool"
    nodes_cidr_block    = "10.51.0.0/16",
    pods_cidr_block     = "192.168.64.0/22"
    services_cidr_block = "192.168.1.0/24"
    region              = data.google_client_config.current.region
  }
}

module "gke" {
  source            = "../../../gke"
  name              = "simple-gke-node-pool"
  network           = module.vpc.name
  ip_range_pods     = module.vpc.gke_subnet_pods_range_name
  ip_range_services = module.vpc.gke_subnet_svc_range_name
  subnetwork        = module.vpc.gke_subnet_name
  subnetwork_cidr   = module.vpc.gke_subnet_cidr_block
  kubeconfig_path   = abspath("${path.root}/generated/kubeconfig")
  autopilot         = false # Standard GKE
  private           = false # public GKE
}

module "node_pool" {
  source             = "../../../node-pool"
  cluster_name       = module.gke.name
  cluster_location   = module.gke.location
  service_account    = module.gke.service_account
  min_master_version = null
  node_pools = {
    simple = {
      initial_node_count = 0
    }
  }
}
