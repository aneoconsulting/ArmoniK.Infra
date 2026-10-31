data "google_client_openid_userinfo" "current" {}

locals {
  labels = {
    env    = "test"
    app    = "complete"
    module = "gke"
    # Label values only allow lowercase letters, digits, "_" and "-"
    created_by = replace(lower(split("@", data.google_client_openid_userinfo.current.email)[0]), "/[^a-z0-9_-]/", "_")
  }
}

module "vpc" {
  source = "../../../../../networking/gcp/vpc"
  name   = "gke-complete"
  gke_subnet = {
    name                = "gke-complete"
    nodes_cidr_block    = "10.43.0.0/16"
    pods_cidr_block     = "172.16.0.0/16"
    services_cidr_block = "172.17.17.0/24"
    region              = var.region
    # Private nodes reach public registries through Cloud NAT
    public_access = true
  }
}

# Encrypts the Kubernetes secrets stored in etcd and the boot disks of the nodes
module "kms" {
  source        = "../../../../../security/gcp/kms"
  key_ring_name = "gke-complete"
  location      = var.region
  crypto_keys = {
    "gke-secrets" = {}
    "gke-disks"   = {}
  }
  labels = local.labels
}

module "complete_gke" {
  source              = "../../../gke-cluster"
  name                = "gke-complete"
  description         = "Complete GKE example"
  network             = module.vpc.name
  subnetwork          = module.vpc.gke_subnet_name
  ip_range_pods       = module.vpc.gke_subnet_pods_range_name
  ip_range_services   = module.vpc.gke_subnet_svc_range_name
  regional            = false
  zones               = ["${var.region}-a"]
  deletion_protection = false
  kms_key             = { id = module.kms.crypto_key_ids["gke-secrets"] }
  boot_disk_kms_key   = { id = module.kms.crypto_key_ids["gke-disks"] }
  kubeconfig_path     = "generated/kubeconfig"
  # No IP endpoint at all: the DNS endpoint accepts any caller with IAM permissions
  control_plane = {
    enable_ip_endpoint         = false
    dns_allow_external_traffic = true
  }
  autoscaling = {
    node_auto_provisioning = {
      max_cpu_cores = 64
      max_memory_gb = 256
    }
  }
  node_pools = {
    system = {
      machine_type = "e2-standard-4"
      min_count    = 1
      max_count    = 3
    }
    # Spot nodes from 0, a local SSD for the emptyDir volumes, a grace period to drain on preemption
    compute = {
      machine_type              = "n2d-standard-8"
      spot                      = true
      total_min_count           = 0
      total_max_count           = 10
      location_policy           = "ANY"
      ephemeral_local_ssd_count = 1
      kubelet = {
        max_parallel_image_pulls      = 5
        shutdown_grace_period_seconds = 30
      }
      labels = { workload = "compute" }
      taints = [{ key = "workload", value = "compute", effect = "NO_SCHEDULE" }]
    }
  }
  labels = local.labels
}
