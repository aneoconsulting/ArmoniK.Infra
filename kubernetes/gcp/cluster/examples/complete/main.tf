module "vpc" {
  source     = "../../../../../networking/gcp/vpc"
  name       = var.network
  gke_subnet = var.gke_subnet
}
locals {
  kubeconfig_path = coalesce(var.kubeconfig_path, "${path.module}/kubeconfig")
}
module "gke" {
  source                      = "../../../../gcp/cluster"
  project_id                  = var.project
  name                        = var.cluster_name
  regional                    = true
  region                      = var.region
  network                     = module.vpc.name
  subnetwork                  = module.vpc.gke_subnet_name
  ip_range_pods               = module.vpc.gke_subnet_pods_range_name
  ip_range_services           = module.vpc.gke_subnet_svc_range_name
  create_service_account      = true
  remove_default_node_pool    = true
  kubeconfig_path             = local.kubeconfig_path
  initial_node_count          = 1
  enable_binary_authorization = true

  cluster_autoscaling = {
    enabled             = false
    autoscaling_profile = "BALANCED"
    max_cpu_cores       = 0
    min_cpu_cores       = 0
    max_memory_gb       = 0
    min_memory_gb       = 0
    gpu_resources       = []
    auto_repair         = true
    auto_upgrade        = true
  }
  horizontal_pod_autoscaling = true
  http_load_balancing        = true
  node_pools = [
    {
      name               = "default-node-pool"
      machine_type       = "e2-medium"
      node_locations     = "us-central1-b,us-central1-c"
      min_count          = 1
      max_count          = 100
      local_ssd_count    = 0
      spot               = false
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      initial_node_count = 80
    },
  ]
}


