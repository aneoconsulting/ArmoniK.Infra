variable "name" {
  description = "Name of the cluster: up to 40 lowercase letters, digits or hyphens, starting with a letter. Its first 20 characters name the node service account."
  type        = string
  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{0,38}[a-z0-9])?$", var.name))
    error_message = "\"name\" must be up to 40 lowercase letters, digits or hyphens, start with a letter and not end with a hyphen."
  }
}

variable "description" {
  description = "Description of the cluster."
  type        = string
  default     = null
}

variable "autopilot" {
  description = "Create an Autopilot cluster instead of a Standard one. Changing it recreates the cluster."
  type        = bool
  default     = false
  nullable    = false
}

variable "regional" {
  description = "Standard only, Autopilot clusters are regional. Create a regional cluster, or a zonal one in the first of \"zones\". Changing it recreates the cluster."
  type        = bool
  default     = true
  nullable    = false
  validation {
    condition     = var.regional || !var.autopilot
    error_message = "An Autopilot cluster is regional: \"regional\" cannot be false."
  }
}

variable "region" {
  description = "Region of a regional or Autopilot cluster. Defaults to the provider region; ignored for a zonal cluster, whose region is the one of its zone."
  type        = string
  default     = null
}

variable "zones" {
  description = "Zones of the nodes. Regional or Autopilot cluster: every zone of the region by default. Zonal cluster: required, the first one is the zone of the cluster."
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = var.autopilot || var.regional || length(var.zones) > 0
    error_message = "\"zones\" must list at least one zone when \"regional\" is false."
  }
}

variable "network" {
  description = "Name of the VPC network of the cluster."
  type        = string
}

variable "subnetwork" {
  description = "Name of the subnetwork of the nodes, in the region of the cluster."
  type        = string
}

variable "network_project_id" {
  description = "Project of the network, for a Shared VPC. Defaults to the provider project."
  type        = string
  default     = null
}

variable "ip_range_pods" {
  description = "Name of the secondary range of the subnetwork for the Pods."
  type        = string
}

variable "ip_range_services" {
  description = "Name of the secondary range of the subnetwork for the Services."
  type        = string
}

variable "release_channel" {
  description = "Release channel of the cluster, which upgrades the control plane and the nodes automatically."
  type        = string
  default     = "REGULAR"
  nullable    = false
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE", "EXTENDED"], var.release_channel)
    error_message = "Valid values for \"release_channel\" are: \"RAPID\" | \"REGULAR\" | \"STABLE\" | \"EXTENDED\"."
  }
}

variable "kubernetes_version" {
  description = "Minimum Kubernetes version of the control plane, or \"latest\" for the default version of the release channel."
  type        = string
  default     = "latest"
  nullable    = false
}

variable "enable_private_nodes" {
  description = "Nodes get internal IP addresses only. They reach the internet through Cloud NAT."
  type        = bool
  default     = true
  nullable    = false
}

variable "enable_private_endpoint" {
  description = "The control plane has no public IP endpoint: it is reachable from the VPC, and through the DNS endpoint when \"dns_allow_external_traffic\" is true. Requires \"enable_private_nodes\"."
  type        = bool
  default     = true
  nullable    = false
  validation {
    condition     = !var.enable_private_endpoint || var.enable_private_nodes
    error_message = "\"enable_private_endpoint\" requires \"enable_private_nodes\"."
  }
}

variable "master_ipv4_cidr_block" {
  description = "/28 range of the control plane in the VPC. GKE chooses one by default."
  type        = string
  default     = null
}

variable "master_global_access_enabled" {
  description = "With a private endpoint, it is reachable from every region of the VPC, not only from the region of the cluster."
  type        = bool
  default     = true
  nullable    = false
}

variable "master_authorized_networks" {
  description = "CIDR blocks allowed to reach the IP endpoints of the control plane, besides the nodes. Empty: no external IP reaches the public endpoint."
  type = list(object({
    cidr_block   = string
    display_name = optional(string)
  }))
  default  = []
  nullable = false
}

variable "dns_allow_external_traffic" {
  description = "The DNS endpoint of the control plane accepts calls from outside the VPC, authenticated by IAM, whatever their IP."
  type        = bool
  default     = false
  nullable    = false
}

variable "deletion_protection" {
  description = "Refuse the deletion of the cluster by Terraform."
  type        = bool
  default     = true
  nullable    = false
}

variable "kms_key" {
  description = "Cloud KMS key, in the region of the cluster, that encrypts the Kubernetes secrets in etcd. An object, so that the key can be created in the same apply: its ID is unknown at plan time, the object is not."
  type = object({
    id = string
  })
  default = null
}

variable "datapath_provider" {
  description = "Standard only, always ADVANCED_DATAPATH on Autopilot. ADVANCED_DATAPATH enables Dataplane V2, which enforces the network policies; LEGACY_DATAPATH keeps kube-proxy, without network policies. Changing it recreates the cluster."
  type        = string
  default     = "ADVANCED_DATAPATH"
  nullable    = false
  validation {
    condition     = contains(["ADVANCED_DATAPATH", "LEGACY_DATAPATH"], var.datapath_provider)
    error_message = "Valid values for \"datapath_provider\" are: \"ADVANCED_DATAPATH\" | \"LEGACY_DATAPATH\"."
  }
}

variable "default_max_pods_per_node" {
  description = "Standard only. Maximum number of Pods per node, which sizes the Pod range of each node. Changing it recreates the cluster."
  type        = number
  default     = 110
  nullable    = false
}

variable "disable_default_snat" {
  description = "Disable the SNAT of the Pod traffic to the node IP, to keep the Pod IP behind Cloud NAT or to use public IP ranges privately."
  type        = bool
  default     = false
  nullable    = false
}

variable "node_pools" {
  description = "Standard only, ignored on Autopilot, which manages the nodes. Node pools keyed by name, with autoscaling between min_count and max_count nodes per zone, or between total_min_count and total_max_count nodes over all the zones of the pool when both are set. Default: a single \"default-node-pool\" with the defaults below."
  type = map(object({
    machine_type       = optional(string, "e2-medium")
    image_type         = optional(string, "COS_CONTAINERD")
    disk_size_gb       = optional(number, 100)
    disk_type          = optional(string, "pd-standard")
    spot               = optional(bool, false)
    min_count          = optional(number, 1)
    max_count          = optional(number, 100)
    total_min_count    = optional(number)
    total_max_count    = optional(number)
    initial_node_count = optional(number)
    location_policy    = optional(string)
    node_locations     = optional(list(string))
    max_pods_per_node  = optional(number)
    labels             = optional(map(string), {})
    resource_labels    = optional(map(string), {})
    tags               = optional(list(string), [])
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  # The default goes through the type above, which fills in the optional attributes. A default built in the
  # module instead (coalesce) would be unified with this type into a map of strings, dropping them.
  default = {
    "default-node-pool" = {}
  }
  nullable = false
  validation {
    condition     = alltrue([for pool in values(var.node_pools) : (pool.total_min_count == null) == (pool.total_max_count == null)])
    error_message = "\"total_min_count\" and \"total_max_count\" of a node pool must be set together."
  }
}

variable "service_account" {
  description = "Email of an existing service account for the nodes. Null: the module creates one with the roles/container.defaultNodeServiceAccount role."
  type        = string
  default     = null
}

variable "grant_registry_access" {
  description = "Grant the Artifact Registry reader role on the project to the node service account the module creates."
  type        = bool
  default     = true
  nullable    = false
}

variable "http_load_balancing" {
  description = "Enable the HTTP load balancing add-on (GKE Ingress, NEG)."
  type        = bool
  default     = true
  nullable    = false
}

variable "horizontal_pod_autoscaling" {
  description = "Enable the horizontal Pod autoscaling add-on, which KEDA relies on."
  type        = bool
  default     = true
  nullable    = false
}

variable "dns_cache" {
  description = "Standard only, always on with Autopilot. Enable NodeLocal DNSCache."
  type        = bool
  default     = false
  nullable    = false
}

variable "enable_vertical_pod_autoscaling" {
  description = "Standard only, always on with Autopilot. Enable vertical Pod autoscaling."
  type        = bool
  default     = false
  nullable    = false
}

variable "maintenance" {
  description = "Maintenance window. Without recurrence, a daily window starting at start_time (HH:MM, UTC). With recurrence (RFC 5545 RRULE), start_time and end_time are RFC 3339 dates."
  type = object({
    start_time = string
    end_time   = optional(string)
    recurrence = optional(string)
  })
  default = {
    start_time = "05:00"
  }
  nullable = false
  validation {
    condition     = (var.maintenance.end_time == null) == (var.maintenance.recurrence == null)
    error_message = "\"maintenance.end_time\" and \"maintenance.recurrence\" go together."
  }
}

variable "labels" {
  description = "Labels of the cluster and of the nodes of its node pools."
  type        = map(string)
  default     = {}
  nullable    = false
}
