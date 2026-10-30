data "google_client_openid_userinfo" "current" {}

locals {
  labels = {
    env             = "test"
    app             = "autopilot-complete"
    module          = "gke"
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
  source = "../../../../../../networking/gcp/vpc"
  name   = "autopilot-gke-complete"
  gke_subnet = {
    name                = "autopilot-gke-complete"
    nodes_cidr_block    = "10.43.0.0/16",
    pods_cidr_block     = "172.16.0.0/16"
    services_cidr_block = "172.17.17.0/24"
    region              = var.region
  }
}

# For more parameters see [Documentation](kubernetes/gcp/gke/README.md)
module "gke" {
  source                  = "../../.."
  name                    = "autopilot"
  network                 = module.vpc.name
  ip_range_pods           = module.vpc.gke_subnet_pods_range_name
  ip_range_services       = module.vpc.gke_subnet_svc_range_name
  subnetwork              = module.vpc.gke_subnet_name
  subnetwork_cidr         = module.vpc.gke_subnet_cidr_block
  kubeconfig_path         = abspath("${path.root}/generated/kubeconfig")
  cluster_resource_labels = merge(local.labels, { resources = "cluster" })
  database_encryption = [
    # default value
    {
      state    = "DECRYPTED"
      key_name = ""
    }
  ]
  description                = "Test GKE Autopilot with beta functionalities."
  enable_confidential_nodes  = true
  grant_registry_access      = true # default value
  horizontal_pod_autoscaling = true
  http_load_balancing        = true # default value
  master_authorized_networks = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "External"
    }
  ]
  private                    = false # public autopilot GKE
  workload_config_audit_mode = "BASIC"
}
