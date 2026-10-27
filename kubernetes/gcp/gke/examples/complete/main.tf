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
  # Only this CIDR block reaches the public endpoint; the DNS endpoint accepts any caller with IAM permissions
  master_authorized_networks = [
    {
      cidr_block   = var.authorized_cidr_block
      display_name = "authorized"
    }
  ]
  dns_allow_external_traffic = true
  database_encryption = [
    {
      state    = "ENCRYPTED"
      key_name = module.kms.crypto_key_ids["gke-secrets"]
    }
  ]
  node_pools = [
    {
      name         = "system"
      machine_type = "e2-standard-4"
      min_count    = 1
      max_count    = 3
      disk_type    = "pd-balanced"
    },
    {
      name         = "compute"
      machine_type = "n2d-standard-4"
      min_count    = 0
      max_count    = 10
      spot         = true
      disk_type    = "pd-balanced"
    },
  ]
  node_pools_labels = {
    compute = { workload = "compute" }
  }
  node_pools_taints = {
    compute = [{ key = "workload", value = "compute", effect = "NO_SCHEDULE" }]
  }
  node_pools_resource_labels = {
    all = local.labels
  }
  cluster_resource_labels = local.labels
}
