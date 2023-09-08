module "vpc" {
  source     = "../../../../../networking/gcp/vpc"
  name       = "gke-simple-test"
  gke_subnet = {
    name                = "gke-simple-test"
    nodes_cidr_block    = "10.43.0.0/16",
    pods_cidr_block     = "172.16.0.0/16"
    services_cidr_block = "172.17.17.0/24"
    region              = var.region
  }
}

module "gke" {
  source                     = "../../../gke"
  name                       = "gke-simple-test"
  network                    = module.vpc.name
  ip_range_pods              = module.vpc.gke_subnet_pods_range_name
  ip_range_services          = module.vpc.gke_subnet_svc_range_name
  subnetwork                 = module.vpc.gke_subnet_name
  subnetwork_cidr            = module.vpc.gke_subnet_cidr_block
  kubeconfig_path            = abspath("${path.root}/generated/kubeconfig")
  # GKE is private by default, add 0.0.0.0/0 to master_authorized_networks
  # to access GKE from outside of the GCP VPC.
  master_authorized_networks = [{ cidr_block = "0.0.0.0/0", display_name = "EXTERNAL" }]
}
