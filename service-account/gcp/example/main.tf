locals {
  cidr        = "10.0.0.0/8"
  name_prefix = "test"
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

module "complete_vpc" {
  source = "../../../networking/gcp/vpc"
  name   = "complete-${random_string.suffix.result}"
  gke_subnets = {
    "gke-alpha" = {
      nodes_cidr_block    = "10.51.0.0/16",
      pods_cidr_block     = "192.168.64.0/22"
      services_cidr_block = "192.168.1.0/24"
      region              = var.region
    }
  }
}

module "gke" {
  source     = "terraform-google-modules/kubernetes-engine/google"
  project_id = var.project_id
  name       = "${local.name_prefix}-gke-cluster"
  region     = var.region
  network                    = module.complete_vpc.name
  subnetwork                 = "gke-alpha"
  ip_range_pods              = module.complete_vpc.gke_subnet_pod_ranges["gke-alpha"].range_name
  ip_range_services          = module.complete_vpc.gke_subnet_svc_ranges["gke-alpha"].range_name
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false

  node_pools = [
    {
      name               = local.name_prefix
      machine_type       = "e2-medium"
      min_count          = 1
      max_count          = 10
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
      initial_node_count = 1
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = { workload_metadata_config = "GKE_METADATA" }

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}

module "service_account" {
  source        = "../"
  gcp_sa_name   = "${local.name_prefix}-gcp-sa"
  project_id    = var.project_id
  k8s_sa_name   = "${local.name_prefix}-k8s-sa"
  K8s_namespace = "${local.name_prefix}-k8s-ns"
  roles         = var.roles

}

resource "kubernetes_pod" "test" {
  metadata {
    name      = "${local.name_prefix}-pod"
    namespace = "${local.name_prefix}-k8s-ns"
  }
  spec {
    container {
      image   = var.image
      name    = "${local.name_prefix}-image"
      command = ["sleep", "infinity"]
    }
    service_account_name = module.service_account.k8s_sa_name
  }
}
