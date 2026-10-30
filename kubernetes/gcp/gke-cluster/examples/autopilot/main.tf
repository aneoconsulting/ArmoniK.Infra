data "google_client_openid_userinfo" "current" {}

locals {
  labels = {
    env    = "test"
    app    = "autopilot"
    module = "gke"
    # Label values only allow lowercase letters, digits, "_" and "-"
    created_by = replace(lower(split("@", data.google_client_openid_userinfo.current.email)[0]), "/[^a-z0-9_-]/", "_")
  }
}

module "vpc" {
  source = "../../../../../networking/gcp/vpc"
  name   = "gke-autopilot"
  gke_subnet = {
    name                = "gke-autopilot"
    nodes_cidr_block    = "10.43.0.0/16"
    pods_cidr_block     = "172.16.0.0/16"
    services_cidr_block = "172.17.17.0/24"
    region              = var.region
    # Private nodes reach public registries through Cloud NAT
    public_access = true
  }
}

# Encrypts the Kubernetes secrets stored in etcd
module "kms" {
  source        = "../../../../../security/gcp/kms"
  key_ring_name = "gke-autopilot"
  location      = var.region
  crypto_keys   = { "gke-secrets" = {} }
  labels        = local.labels
}

module "autopilot_gke" {
  source              = "../../../gke-cluster"
  name                = "gke-autopilot"
  autopilot           = true
  description         = "Autopilot GKE example"
  network             = module.vpc.name
  subnetwork          = module.vpc.gke_subnet_name
  ip_range_pods       = module.vpc.gke_subnet_pods_range_name
  ip_range_services   = module.vpc.gke_subnet_svc_range_name
  zones               = ["${var.region}-a", "${var.region}-b"]
  deletion_protection = false
  # No public IP endpoint (module default): reachable from outside the VPC through the DNS endpoint, with IAM
  dns_allow_external_traffic = true
  kms_key                    = { id = module.kms.crypto_key_ids["gke-secrets"] }
  labels                     = local.labels
}
