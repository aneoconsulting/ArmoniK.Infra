/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  cluster_ca_certificate = module.gke.ca_certificate
  endpoint               = module.gke.endpoint
  context                = module.gke.name
}

data "google_client_config" "current" {}

resource "local_file" "kubeconfig" {
  filename          = "kubeconfig_node_pool_complete.yaml"
  sensitive_content = <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${local.cluster_ca_certificate}
    server: https://${local.endpoint}
  name: ${local.context}
contexts:
- context:
    cluster: ${local.context}
    user: ${local.context}
  name: ${local.context}
current-context: ${local.context}
kind: Config
preferences: {}
users:
- name: ${local.context}
  user:
    token: ${data.google_client_config.current.access_token}
EOF
}

module "vpc" {
  source     = "../../../../../networking/gcp/vpc"
  name       = var.network
  gke_subnet = var.gke_subnet
}

module "gke" {
  source                   = "terraform-google-modules/kubernetes-engine/google"
  version                  = "27.0.0"
  project_id               = var.project
  name                     = var.cluster_name
  regional                 = true
  region                   = var.region
  network                  = module.vpc.name
  subnetwork               = module.vpc.gke_subnet_name
  ip_range_pods            = module.vpc.gke_subnet_pods_range_name
  ip_range_services        = module.vpc.gke_subnet_svc_range_name
  create_service_account   = false
  service_account          = var.service_account
  remove_default_node_pool = true
}

module "node_pool" {
  source             = "../../../node_pool"
  cluster_name       = module.gke.name
  service_account    = var.service_account
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
      service_account             = var.service_account
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
      service_account    = var.service_account
      preemptible        = false
      initial_node_count = 0
      enable_secure_boot = false
      autoscaling        = false
      node_count         = 0
      tags               = ["second"]
      strategy           = "BLUE_GREEN"
      max_pods_per_node  = 100
      batch_percentage   = 0.2
      taint = { "complete-node-pool-2" : { value  = true, effect = "PREFER_NO_SCHEDULE" } }
    }
  }

  base_tags   = ["complete"]
  base_labels = { "example" : "complete" }
  base_taints = { "complete" : { value = true, effect = "PREFER_NO_SCHEDULE" } }
}
