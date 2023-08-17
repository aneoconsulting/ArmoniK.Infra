variable "min_master_version" {
  description = "The minimum version of the cluster master"
  type        = string
  default     = null
}

variable "release_channel" {
  description = "The release channel of this cluster. Accepted values are `UNSPECIFIED`, `RAPID`, `REGULAR` and `STABLE`. Defaults to `REGULAR`"
  type        = string
  default     = "REGULAR"
}

variable "disable_legacy_metadata_endpoints" {
  description = "Disable the /0.1/ and /v1beta1/ metadata server endpoints on the node. Changing this value will cause all node pools to be recreated"
  type        = bool
  default     = true
}

variable "timeouts" {
  description = "A map of timeouts for cluster operations"
  type        = map(string)
  default     = {}
  validation {
    condition     = !contains([for t in keys(var.timeouts) : contains(["create", "update", "delete"], t)], false)
    error_message = "Only create, update, delete timeouts can be specified"
  }
}

variable "service_account" {
  type        = string
  description = "The service account to run nodes"
  default     = ""
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster to create the node pools for"
  default     = ""
}

variable "cluster_location" {
  type        = string
  description = "Cluster location (region or zone)"
  default     = ""
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

variable "base_oauth_scopes" {
  description = "List of oauth scopes used for all node pools, you can add specific oauth scopes to specific node pools in node_pools variable with the 'oauth_scopes' key"
  type        = list(string)
  default     = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "base_tags" {
  description = "List of tags used for all node pools, you can add specific tags to specific node pools in node_pools variable with the 'tags' key"
  type        = list(string)
  default     = []
}

variable "base_labels" {
  description = "Map of labels used for all node pools, you can add specific labels to specific node pools in node_pools variable with the 'labels' key"
  type        = map(string)
  default     = {}
}

variable "base_resource_labels" {
  description = "Map of resource labels used for all node pools, you can add specific resource labels to specific node pools in node_pools variable with the 'resource_labels' key"
  type        = map(string)
  default     = {}
}

variable "base_metadata" {
  description = "Map of metadata used for all node pools, you can add specific metadata to specific node pools in node_pools variable with the 'metadata' key"
  type        = map(any)
  default     = {}
}

variable "node_pools" {
  type        = any
  description = "Map of maps containing the node pools configurations. Multiple keys can be used within a node pool configuration, see : https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool"
  default     = {}
}

variable "windows_node_pools" {
  type        = any
  description = "Map of maps containing Windows node pools configurations. All keys used for node pool configurations in node_pools can be used in windows_node_pools, see : https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool"
  default     = {}
}
