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
  }
}

# Encrypts the Kubernetes secrets stored in etcd
module "kms" {
  source        = "../../../../../security/gcp/kms"
  key_ring_name = "gke-complete"
  location      = var.region
  crypto_keys   = { "gke-secrets" = {} }
  labels        = local.labels
}

module "complete_gke" {
  source              = "../../../gke"
  name                = "gke-complete"
  description         = "Complete GKE example"
  network             = module.vpc.name
  subnetwork          = module.vpc.gke_subnet_name
  ip_range_pods       = module.vpc.gke_subnet_pods_range_name
  ip_range_services   = module.vpc.gke_subnet_svc_range_name
  regional            = false
  zones               = ["${var.region}-a"]
  deletion_protection = false
  # Public IP endpoint reachable from this CIDR block only; the DNS endpoint accepts any caller with IAM permissions
  enable_private_endpoint = false
  master_authorized_networks = [
    {
      cidr_block   = var.authorized_cidr_block
      display_name = "authorized"
    }
  ]
  dns_allow_external_traffic = true
  kms_key                    = { id = module.kms.crypto_key_ids["gke-secrets"] }
  node_pools = {
    system = {
      machine_type = "e2-standard-4"
      min_count    = 1
      max_count    = 3
      disk_type    = "pd-balanced"
    }
    compute = {
      machine_type = "n2d-standard-4"
      min_count    = 0
      max_count    = 10
      spot         = true
      disk_type    = "pd-balanced"
      labels       = { workload = "compute" }
      taints       = [{ key = "workload", value = "compute", effect = "NO_SCHEDULE" }]
    }
  }
  labels = local.labels
}
