data "google_client_config" "current" {}

data "google_client_openid_userinfo" "current" {}

locals {
  base_labels = {
    env             = "test"
    app             = "complete"
    module          = "gke-node-pool"
    "create_by"     = split("@", data.google_client_openid_userinfo.current.email)[0]
    "creation_date" = "date-${null_resource.timestamp.triggers["date"]}"
  }
  base_tags = values(local.base_labels)
  date      = <<-EOT
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
  source = "../../../../../networking/gcp/vpc"
  name   = "simple-gke-node-pool"
  gke_subnet = {
    name                = "simple-gke-node-pool"
    nodes_cidr_block    = "10.51.0.0/16",
    pods_cidr_block     = "192.168.64.0/22"
    services_cidr_block = "192.168.1.0/24"
    region              = data.google_client_config.current.region
  }
}

module "gke" {
  source            = "../../../gke"
  name              = "simple-gke-node-pool"
  network           = module.vpc.name
  ip_range_pods     = module.vpc.gke_subnet_pods_range_name
  ip_range_services = module.vpc.gke_subnet_svc_range_name
  subnetwork        = module.vpc.gke_subnet_name
  subnetwork_cidr   = module.vpc.gke_subnet_cidr_block
  kubeconfig_path   = abspath("${path.root}/generated/kubeconfig")
  autopilot         = false # Standard GKE
  private           = false # public GKE
}

module "node_pool" {
  source             = "../.."
  cluster_name       = module.gke.name
  cluster_location   = module.gke.location
  service_account    = module.gke.service_account
  min_master_version = null
  node_pools = {
    complete-1 = {
      machine_type                = "e2-medium"
      node_locations              = "europe-west9-a,europe-west9-b"
      local_ssd_count             = 0
      spot                        = false
      disk_size_gb                = 100
      disk_type                   = "pd-standard"
      image_type                  = "COS_CONTAINERD"
      enable_gcfs                 = false
      enable_gvnic                = false
      auto_repair                 = true
      auto_upgrade                = true
      service_account             = module.gke.service_account
      preemptible                 = false
      initial_node_count          = 0
      enable_secure_boot          = false
      enable_integrity_monitoring = false
      autoscaling                 = true
      min_count                   = 0
      max_count                   = 100
      location_policy             = "BALANCED"
      tags                        = ["first"]
      strategy                    = "SURGE"
      max_pods_per_node           = 100
    }
    complete-2 = {
      machine_type       = "e2-medium"
      node_locations     = "europe-west9-a,europe-west9-b"
      local_ssd_count    = 0
      spot               = false
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      auto_repair        = true
      auto_upgrade       = true
      service_account    = module.gke.service_account
      preemptible        = false
      initial_node_count = 0
      enable_secure_boot = false
      autoscaling        = false
      node_count         = 0
      tags               = ["second"]
      strategy           = "BLUE_GREEN"
      max_pods_per_node  = 100
      batch_percentage   = 0.2
      taint              = { "complete-node-pool-2" : { value = true, effect = "PREFER_NO_SCHEDULE" } }
    }
  }
  base_tags   = local.base_tags
  base_labels = local.base_labels
  base_taints = { "complete" : { value = true, effect = "PREFER_NO_SCHEDULE" } }
}
