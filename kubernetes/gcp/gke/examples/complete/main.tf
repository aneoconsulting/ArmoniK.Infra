data "google_client_openid_userinfo" "current" {}

data "google_compute_zones" "available" {
  project = var.project
  region  = var.region
  status  = "UP"
}

locals {
  labels = {
    env             = "test"
    app             = "complete"
    module          = "gcp-gke-standard"
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
  source = "../../../../../networking/gcp/vpc"
  name   = "gke-complete"
  gke_subnet = {
    name                = "gke-complete"
    nodes_cidr_block    = "10.43.0.0/16",
    pods_cidr_block     = "172.16.0.0/16"
    services_cidr_block = "172.17.17.0/24"
    region              = var.region
  }
}

# For more parameters see [Documentation](kubernetes/gcp/gke/README.md)
module "gke" {
  source            = "../../../gke"
  name              = "complete"
  network           = module.vpc.name
  ip_range_pods     = module.vpc.gke_subnet_pods_range_name
  ip_range_services = module.vpc.gke_subnet_svc_range_name
  subnetwork        = module.vpc.gke_subnet_name
  subnetwork_cidr   = module.vpc.gke_subnet_cidr_block
  kubeconfig_path   = abspath("${path.root}/generated/kubeconfig")
  cluster_autoscaling = {
    # default value
    enabled             = false
    autoscaling_profile = "BALANCED"
    auto_repair         = true
    auto_upgrade        = true
    disk_size           = 100
    disk_type           = "pd-standard"
    gpu_resources       = []
    max_cpu_cores       = 0
    min_cpu_cores       = 0
    max_memory_gb       = 0
    min_memory_gb       = 0
  }
  cluster_resource_labels = merge(local.labels, { resources = "cluster" })
  config_connector        = true
  create_service_account  = true # default value
  database_encryption = [
    # default value
    {
      state    = "DECRYPTED"
      key_name = ""
    }
  ]
  default_max_pods_per_node   = 256
  description                 = "Test GKE Standard with beta functionalities."
  enable_confidential_nodes   = true
  enable_identity_service     = true
  enable_intranode_visibility = true
  enable_shielded_nodes       = true # default value
  filestore_csi_driver        = true
  gce_pd_csi_driver           = true
  gke_backup_agent_config     = true
  grant_registry_access       = true # default value
  horizontal_pod_autoscaling  = true
  http_load_balancing         = true # default value
  initial_node_count          = 0    # default value
  istio                       = true
  logging_enabled_components  = ["SYSTEM_COMPONENTS"]
  master_authorized_networks = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "External"
    }
  ]
  monitoring_enabled_components = ["SYSTEM_COMPONENTS"]
  node_pools = [
    {
      name               = "example"
      machine_type       = "n2d-standard-2"
      node_locations     = join(",", data.google_compute_zones.available.names)
      min_count          = 0
      max_count          = 100
      local_ssd_count    = 0
      spot               = true
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = true
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
      initial_node_count = 0
    },
  ]
  node_pools_labels = { all = merge(local.labels, { resources = "node-pools" }) }
  node_pools_resource_labels = {
    all               = merge(local.labels, { resources = "node-pool-resources" })
    default-node-pool = merge(local.labels, { resources = "node-pool-resources" })
  }
  node_pools_tags = {
    all = [
      "tag-test",
      "tag-complete",
      "tag-gke-standard",
      "tag-${split("@", data.google_client_openid_userinfo.current.email)[0]}",
      "tag-${null_resource.timestamp.triggers["date"]}"
    ]
  }
  private                    = false # public Standard GKE
  remove_default_node_pool   = true  # default value
  sandbox_enabled            = true
  windows_node_pools         = [] # default value
  workload_config_audit_mode = "BASIC"
}
