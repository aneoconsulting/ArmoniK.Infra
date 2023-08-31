module "vpc" {
  source     = "../../../../../networking/gcp/vpc"
  name       = var.network
  gke_subnet = var.gke_subnet
}
locals {
  kubeconfig_path = coalesce(var.kubeconfig_path, "${path.module}/kubeconfig")
}
module "gke" {
  source                   = "../../../../gcp/cluster"
  project_id               = var.project
  name                     = var.cluster_name
  regional                 = true
  region                   = var.region
  network                  = module.vpc.name
  subnetwork               = module.vpc.gke_subnet_name
  ip_range_pods            = module.vpc.gke_subnet_pods_range_name
  ip_range_services        = module.vpc.gke_subnet_svc_range_name
  create_service_account   = false
  service_account          = "tf-gke-gke-test-1-k4hk@armonik-gcp-13469.iam.gserviceaccount.com"
  remove_default_node_pool = true
  kubeconfig_path          = local.kubeconfig_path
}
