/**
 * Copyright 2022 Google LLC
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

variable "min_master_version" {
  type        = string
  description = "The minimum version of the cluster master"
  default = null
}

variable "release_channel" {
  type        = string
  description = "The release channel of this cluster. Accepted values are `UNSPECIFIED`, `RAPID`, `REGULAR` and `STABLE`. Defaults to `REGULAR`."
  default     = "REGULAR"
}

variable "disable_legacy_metadata_endpoints" {
  type        = bool
  description = "Disable the /0.1/ and /v1beta1/ metadata server endpoints on the node. Changing this value will cause all node pools to be recreated."
  default     = true
}

variable "timeouts" {
  type        = map(string)
  description = "Timeout for cluster operations."
  default     = {}
  validation {
    condition     = !contains([for t in keys(var.timeouts) : contains(["create", "update", "delete"], t)], false)
    error_message = "Only create, update, delete timeouts can be specified."
  }
}

variable "service_account" {
  type        = string
  description = "The service account to run nodes as if not overridden in `node_pools`. The create_service_account variable default value (true) will cause a cluster-specific service account to be created. This service account should already exists and it will be used by the node pools. If you wish to only override the service account name, you can use service_account_name variable."
  default     = ""
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster to create the node pool for"
  default     = ""
}

variable "windows_node_pools" {
  type        = any
  description = "Map of maps containing Windows node pools"
  default     = {}
}

variable "node_metadata" {
  description = "Specifies how node metadata is exposed to the workload running on the node"
  default     = "GKE_METADATA"
  type        = string

  validation {
    condition     = contains(["GKE_METADATA", "GCE_METADATA", "UNSPECIFIED", "GKE_METADATA_SERVER", "EXPOSE"], var.node_metadata)
    error_message = "The node_metadata value must be one of GKE_METADATA, GCE_METADATA, UNSPECIFIED, GKE_METADATA_SERVER or EXPOSE."
  }
}

variable "oauth_scopes" {
  description = "List of oauth scopes used for all node pools"
  type        = list(string)
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "node_pools_tags" {
  description = "List of tags used for all nodes pools"
  type = list(string)
  default = []
}

variable "labels" {
  description = "Map of labels"
  type = map(string)
  default = {}
}

variable "node_pools_metadata" {
  description = "Map of metadata used for all nodes pools"
  type = map(any)
  default = {}
}

variable "resource_labels" {
  description = "Map of tags used for all nodes pools"
  type = map(string)
  default = {}
}

variable "cluster_location" {
  type        = string
  description = "Cluster location (region or zone)"
  default     = ""
}

variable "node_pools" {
  type        = any
  description = "Map of maps containing the node pools configurations. Multiple keys can be used within a node ppol configuration : see "

  default = {}
}