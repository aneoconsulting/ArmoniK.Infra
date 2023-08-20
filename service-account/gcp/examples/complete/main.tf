data "google_client_config" "current" {}

data "google_client_openid_userinfo" "current" {}

locals {
  labels = {
    env             = "test"
    app             = "complete"
    module          = "sa"
    "create_by"     = split("@", data.google_client_openid_userinfo.current.email)[0]
    "creation_date" = null_resource.timestamp.triggers["date"]
  }
  date = <<-EOT
#!/bin/bash
set -e
DATE=$(date +%F-%H-%M-%S)
jq -n --arg date "$DATE" '{"date":$date}'
  EOT
}

resource "local_file" "date_sh" {
  filename = "${path.module}/generated/date.sh"
  content  = local.date
}

data "external" "static_timestamp" {
  program     = ["bash", "date.sh"]
  working_dir = "${path.module}/generated"
  depends_on  = [local_file.date_sh]
}

resource "null_resource" "timestamp" {
  triggers = {
    date = data.external.static_timestamp.result.date
  }
  lifecycle {
    ignore_changes = [triggers]
  }
}

module "vpc" {
  source = "../../../../networking/gcp/vpc"
  name   = "vcp-test-sa"
  gke_subnet = {
    name                = "gke-alpha"
    nodes_cidr_block    = "10.51.0.0/16",
    pods_cidr_block     = "192.168.64.0/22"
    services_cidr_block = "192.168.1.0/24"
    region              = "europe-west9"
  }
  enable_google_access = true
}

module "gke" {
  source                  = "terraform-google-modules/kubernetes-engine/google"
  version                 = "27.0.0"
  project_id              = data.google_client_config.current.project
  name                    = "gke-sa-test"
  region                  = data.google_client_config.current.region
  network                 = module.vpc.name
  subnetwork              = module.vpc.gke_subnet_name
  ip_range_pods           = module.vpc.gke_subnet_pods_range_name
  ip_range_services       = module.vpc.gke_subnet_svc_range_name
  cluster_resource_labels = local.labels
}

module "service_account" {
  source               = "../../../../service-account/gcp"
  service_account_name = "test-service-account-for-pods"
  kubernetes_namespace = "default"
  roles                = ["roles/redis.editor", "roles/pubsub.editor"]
}

resource "kubernetes_pod" "pod" {
  metadata {
    name      = "test-pod"
    namespace = module.service_account.namespace
  }
  spec {
    container {
      image   = "google/cloud-sdk:slim"
      name    = "test-pod"
      command = ["sleep", "infinity"]
    }
    service_account_name = module.service_account.kubernetes_service_account_name
  }
}
