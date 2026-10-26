data "google_client_config" "current" {}

data "google_client_openid_userinfo" "current" {}

# Bucket names are unique across all of GCP
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  labels = {
    env    = "test"
    app    = "complete"
    module = "service-account"
    # Label values only allow lowercase letters, digits, "_" and "-"
    created_by = replace(lower(split("@", data.google_client_openid_userinfo.current.email)[0]), "/[^a-z0-9_-]/", "_")
  }
  namespace       = "default"
  service_account = "complete-sa"
}

module "vpc" {
  source = "../../../../networking/gcp/vpc"
  name   = "complete-sa-${random_string.suffix.result}"
  gke_subnet = {
    name                = "complete-sa-gke"
    nodes_cidr_block    = "10.51.0.0/16"
    pods_cidr_block     = "192.168.64.0/22"
    services_cidr_block = "192.168.1.0/24"
    region              = var.region
  }
  enable_google_access = true
}

# Zonal cluster with Workload Identity enabled (module default)
module "gke" {
  source                  = "terraform-google-modules/kubernetes-engine/google"
  version                 = "46.0.0"
  project_id              = data.google_client_config.current.project
  name                    = "complete-sa-${random_string.suffix.result}"
  region                  = var.region
  regional                = false
  zones                   = ["${var.region}-a"]
  network                 = module.vpc.name
  subnetwork              = module.vpc.gke_subnet_name
  ip_range_pods           = module.vpc.gke_subnet_pods_range_name
  ip_range_services       = module.vpc.gke_subnet_svc_range_name
  deletion_protection     = false
  cluster_resource_labels = local.labels
}

# Workload Identity Federation: the roles go to the Kubernetes service account itself, no GCP service account is
# created. They can be granted before the cluster and the Kubernetes service account exist.
module "complete_service_account" {
  source                     = "../../../gcp"
  kubernetes_namespace       = local.namespace
  kubernetes_service_account = local.service_account
}

module "bucket" {
  source        = "../../../../storage/gcp/gcs"
  name          = "complete-sa-${random_string.suffix.result}"
  location      = var.region
  force_destroy = true
  roles = {
    "roles/storage.objectViewer" = [module.complete_service_account.member]
  }
  labels = local.labels
}

resource "kubernetes_service_account_v1" "test" {
  metadata {
    name      = local.service_account
    namespace = local.namespace
  }
}

resource "kubernetes_pod_v1" "test" {
  metadata {
    name      = "complete-sa-test"
    namespace = local.namespace
  }
  spec {
    service_account_name = kubernetes_service_account_v1.test.metadata[0].name
    container {
      name    = "gcloud"
      image   = "google/cloud-sdk:slim"
      command = ["sleep", "infinity"]
    }
  }
}
