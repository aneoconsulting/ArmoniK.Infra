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

variable "project" {
  description = "Project name"
  type        = string
  default     = "armonik-gcp-13469"
}

variable "region" {
  description = "The region to host the cluster in"
  default     = "europe-west9"
}

variable "cluster_name" {
  description = "The name for the GKE cluster"
  type = string
  default     = "gke-complete-cluster"
}

variable "network" {
  description = "The VPC network created to host the cluster in"
  default     = "gke-complet-network"
}

variable "gke_subnet" {
  description = "Map of GKE subnets"
  type = object({
    name                = string
    nodes_cidr_block    = string
    pods_cidr_block     = string
    services_cidr_block = string
    region              = string
  })
    default = {
      name                = "gke-complete-subnet"
      nodes_cidr_block    = "10.51.0.0/16",
      pods_cidr_block     = "192.168.64.0/22"
      services_cidr_block = "192.168.1.0/24"
      region              = "europe-west9"
    }
  }

variable "node_pools" {
  description = "value"
  type = any
  default = {
    test = {
      name               = "default-node-pool"
      machine_type       = "e2-medium"
      node_locations     = "europe-west9-a,europe-west9-b"
      min_count          = 1
      max_count          = 100
      local_ssd_count    = 0
      spot               = false
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      auto_repair        = true
      auto_upgrade       = true
      service_account    = "tf-gke-gke-test-1-k4hk@armonik-gcp-13469.iam.gserviceaccount.com"
      preemptible        = false
      initial_node_count = 0
    }
    test-2 = {
      name               = "default-node-pool-2"
      machine_type       = "e2-medium"
      node_locations     = "europe-west9-a,europe-west9-b"
      min_count          = 1
      max_count          = 100
      local_ssd_count    = 0
      spot               = false
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      auto_repair        = true
      auto_upgrade       = true
      service_account    = "tf-gke-gke-test-1-k4hk@armonik-gcp-13469.iam.gserviceaccount.com"
      preemptible        = false
      initial_node_count = 0
      taint=[{
        key    = "default-node-pool-2"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      }]
    }
}
}

variable "service_account" {
  description = "value"
  type = string
  default = "tf-gke-gke-test-1-k4hk@armonik-gcp-13469.iam.gserviceaccount.com"
}

variable "location" {
  description = "value"
  type=string
  default = "us-central1"
}