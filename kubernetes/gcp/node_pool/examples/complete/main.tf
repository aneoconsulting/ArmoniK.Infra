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
  cluster_type = "simple-regional"
  cluster_ca_certificate = module.gke.ca_certificate
  endpoint               = module.gke.endpoint
  host                   = "https://${local.endpoint}"
  context                = module.gke.name
}

data "google_client_config" "current" {}
  
module "vpc" {
  source = "../../../../../networking/gcp/vpc"
  name = var.network
  gke_subnet = var.gke_subnet
}

module "gke" {
  source                 = "terraform-google-modules/kubernetes-engine/google"
  project_id             = var.project
  name                   = var.cluster_name
  regional               = true
  region                 = var.region
  network                = module.vpc.name
  subnetwork             = module.vpc.gke_subnet_name
  ip_range_pods          = module.vpc.gke_subnet_pods_range_name
  ip_range_services      = module.vpc.gke_subnet_svc_range_name
  create_service_account = false
  service_account        = "tf-gke-gke-test-1-k4hk@armonik-gcp-13469.iam.gserviceaccount.com"
  remove_default_node_pool=true
}

module "node_pool" {
  depends_on = [ module.gke ]
  source                 = "../../../node_pool"
  
  cluster_name=var.cluster_name
  service_account        = "tf-gke-gke-test-1-k4hk@armonik-gcp-13469.iam.gserviceaccount.com"
  node_pools = var.node_pools
  min_master_version=null
}




