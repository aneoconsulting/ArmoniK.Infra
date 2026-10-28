variable "name" {
  type        = string
  description = "The name of the cluster (required)"
}

variable "network" {
  type        = string
  description = "The VPC network to host the cluster in (required)"
}

variable "subnetwork" {
  type        = string
  description = "The subnetwork to host the cluster in (required)"
}

variable "ip_range_pods" {
  type        = string
  description = "The _name_ of the secondary subnet ip range to use for pods"
}

variable "ip_range_services" {
  type        = string
  description = "The _name_ of the secondary subnet range to use for services. If not provided, the default `34.118.224.0/20` range will be used."
  default     = null
}

variable "region" {
  type        = string
  description = "The region to host the cluster in. Defaults to the provider region"
  default     = null
}

variable "zones" {
  type        = list(string)
  description = "The zones of the region where GKE may create nodes. Defaults to every zone of the region"
  default     = []
}

variable "enable_private_nodes" {
  type        = bool
  description = "Whether nodes have internal IP addresses only"
  default     = true
}

variable "enable_private_endpoint" {
  type        = bool
  description = "Whether the master's internal IP address is used as the cluster endpoint"
  default     = false
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "(Optional) The IP range in CIDR notation to use for the hosted master network."
  default     = null
}

variable "master_global_access_enabled" {
  type        = bool
  description = "Whether the cluster master is accessible globally (from any region) or only within the same region as the private endpoint."
  default     = true
}

variable "master_authorized_networks" {
  type        = list(object({ cidr_block = string, display_name = string }))
  description = "List of master authorized networks. If none are provided, disallow external access (except the cluster node IPs, which GKE automatically whitelists)."
  default     = []
}

variable "dns_allow_external_traffic" {
  description = "(Optional) Controls whether external traffic is allowed over the dns endpoint."
  type        = bool
  default     = null
}

variable "deploy_using_private_endpoint" {
  type        = bool
  description = "A toggle for Terraform and kubectl to connect to the master's internal IP address during deployment."
  default     = false
}

variable "deletion_protection" {
  type        = bool
  description = "Whether or not to allow Terraform to destroy the cluster."
  default     = true
}

variable "add_cluster_firewall_rules" {
  type        = bool
  description = "Create additional firewall rules"
  default     = false
}

variable "add_master_webhook_firewall_rules" {
  type        = bool
  description = "Create master_webhook firewall rules for ports defined in `firewall_inbound_ports`"
  default     = false
}

variable "add_shadow_firewall_rules" {
  type        = bool
  description = "Create GKE shadow firewall (the same as default firewall rules with firewall logs enabled)."
  default     = false
}

variable "authenticator_security_group" {
  type        = string
  description = "The name of the RBAC security group for use with Google security groups in Kubernetes RBAC. Group name must be in format gke-security-groups@yourdomain.com"
  default     = null
}

variable "cluster_ipv4_cidr" {
  type        = string
  default     = null
  description = "The IP address range of the kubernetes pods in this cluster. Default is an automatically assigned CIDR."
}

variable "cluster_resource_labels" {
  type        = map(string)
  description = "The GCE resource labels (a map of key/value pairs) to be applied to the cluster"
  default     = {}
}

variable "database_encryption" {
  description = "Application-layer Secrets Encryption settings. The object format is {state = string, key_name = string}. Valid values of state are: \"ENCRYPTED\"; \"DECRYPTED\". key_name is the name of a CloudKMS key."
  type        = list(object({ state = string, key_name = string }))

  default = [{
    state    = "DECRYPTED"
    key_name = ""
  }]
}

variable "description" {
  type        = string
  description = "The description of the cluster"
  default     = ""
}

variable "disable_default_snat" {
  type        = bool
  description = "Whether to disable the default SNAT to support the private use of public IP addresses"
  default     = false
}

variable "dns_cache" {
  type        = bool
  description = "The status of the NodeLocal DNSCache addon."
  default     = true
}

variable "enable_binary_authorization" {
  type        = bool
  description = "Enable BinAuthZ Admission controller"
  default     = false
}

variable "enable_confidential_nodes" {
  type        = bool
  description = "An optional flag to enable confidential node config."
  default     = false
}

variable "enable_cost_allocation" {
  type        = bool
  description = "Enables Cost Allocation Feature and the cluster name and namespace of your GKE workloads appear in the labels field of the billing export to BigQuery"
  default     = false
}

variable "enable_l4_ilb_subsetting" {
  type        = bool
  description = "Enable L4 ILB Subsetting on the cluster"
  default     = false
}

variable "enable_network_egress_export" {
  type        = bool
  description = "Whether to enable network egress metering for this cluster. If enabled, a daemonset will be created in the cluster to meter network egress traffic."
  default     = false
}

variable "enable_resource_consumption_export" {
  type        = bool
  description = "Whether to enable resource consumption metering on this cluster. When enabled, a table will be created in the resource export BigQuery dataset to store resource consumption data. The resulting table can be joined with the resource usage table or with BigQuery billing export."
  default     = true
}

variable "enable_tpu" {
  type        = bool
  description = "Enable Cloud TPU resources in the cluster. WARNING: changing this after cluster creation is destructive!"
  default     = false
}

variable "enable_vertical_pod_autoscaling" {
  type        = bool
  description = "Vertical Pod Autoscaling automatically adjusts the resources of pods controlled by it"
  default     = true
}

variable "filestore_csi_driver" {
  type        = bool
  description = "The status of the Filestore CSI driver addon, which allows the usage of filestore instance as volumes"
  default     = false
}

variable "firewall_inbound_ports" {
  type        = list(string)
  description = "List of TCP ports for admission/webhook controllers. Either flag `add_master_webhook_firewall_rules` or `add_cluster_firewall_rules` (also adds egress rules) must be set to `true` for inbound-ports firewall rules to be applied."
  default     = ["8443", "9443", "15017"]
}

variable "firewall_priority" {
  type        = number
  description = "Priority rule for firewall rules"
  default     = 1000
}

variable "gateway_api_channel" {
  type        = string
  description = "The gateway api channel of this cluster. Accepted values are `CHANNEL_STANDARD` and `CHANNEL_DISABLED`."
  default     = null
}

variable "gke_backup_agent_config" {
  type        = bool
  description = "Whether Backup for GKE agent is enabled for this cluster."
  default     = false
}

variable "grant_registry_access" {
  type        = bool
  description = "Grants created cluster-specific service account storage.objectViewer and artifactregistry.reader roles."
  default     = true
}

variable "horizontal_pod_autoscaling" {
  type        = bool
  description = "Enable horizontal pod autoscaling addon"
  default     = true
}

variable "http_load_balancing" {
  type        = bool
  description = "Enable httpload balancer addon"
  default     = true
}

variable "identity_namespace" {
  description = "The workload pool to attach all Kubernetes service accounts to. (Default value of `enabled` automatically sets project-based pool `[project_id].svc.id.goog`)"
  type        = string
  default     = "enabled"
}

variable "issue_client_certificate" {
  type        = bool
  description = "Issues a client certificate to authenticate to the cluster endpoint. To maximize the security of your cluster, leave this option disabled. Client certificates don't automatically rotate and aren't easily revocable. WARNING: changing this after cluster creation is destructive!"
  default     = false
}

variable "kubernetes_version" {
  type        = string
  description = "The Kubernetes version of the masters. If set to 'latest' it will pull latest available version in the selected region."
  default     = "latest"
}

variable "logging_enabled_components" {
  type        = list(string)
  description = "List of services to monitor: SYSTEM_COMPONENTS, APISERVER, CONTROLLER_MANAGER, KCP_CONNECTION, KCP_SSHD, KCP_HPA, SCHEDULER, and WORKLOADS. Empty list is default GKE configuration."
  default     = []
  validation {
    condition = alltrue([
      for c in var.logging_enabled_components :
      contains([
        "SYSTEM_COMPONENTS",
        "APISERVER",
        "CONTROLLER_MANAGER",
        "SCHEDULER",
        "KCP_CONNECTION",
        "KCP_SSHD",
        "KCP_HPA",
        "WORKLOADS"
      ], c)
    ])
    error_message = "Valid values are SYSTEM_COMPONENTS, APISERVER, CONTROLLER_MANAGER, SCHEDULER, KCP_CONNECTION, KCP_SSHD, KCP_HPA and WORKLOADS."
  }
}

variable "maintenance_end_time" {
  type        = string
  description = "Time window specified for recurring maintenance operations in RFC3339 format"
  default     = ""
}

variable "maintenance_exclusions" {
  type        = list(object({ name = string, start_time = string, end_time = string, exclusion_scope = string }))
  description = "List of maintenance exclusions. A cluster can have up to three"
  default     = []
}

variable "maintenance_recurrence" {
  type        = string
  description = "Frequency of the recurring maintenance window in RFC5545 format."
  default     = ""
}

variable "maintenance_start_time" {
  type        = string
  description = "Time window specified for daily or recurring maintenance operations in RFC3339 format"
  default     = "05:00"
}

variable "monitoring_enabled_components" {
  type        = list(string)
  description = "List of services to monitor: SYSTEM_COMPONENTS, APISERVER, SCHEDULER, CONTROLLER_MANAGER, STORAGE, HPA, POD, DAEMONSET, DEPLOYMENT, STATEFULSET, KUBELET, CADVISOR, DCGM, and JOBSET. In beta provider, WORKLOADS is supported on top of those 12 values. (WORKLOADS is deprecated and removed in GKE 1.24.) KUBELET and CADVISOR are only supported in GKE 1.29.3-gke.1093000 and above. JOBSET is only supported in GKE 1.32.1-gke.1357001 and above. Empty list is default GKE configuration."
  default     = []
  validation {
    condition = alltrue([
      for c in var.monitoring_enabled_components :
      contains([
        "SYSTEM_COMPONENTS",
        "APISERVER",
        "SCHEDULER",
        "CONTROLLER_MANAGER",
        "STORAGE",
        "HPA",
        "POD",
        "DAEMONSET",
        "DEPLOYMENT",
        "STATEFULSET",
        "WORKLOADS",
        "KUBELET",
        "CADVISOR",
        "DCGM",
        "JOBSET"
      ], c)
    ])
    error_message = "Valid values are SYSTEM_COMPONENTS, APISERVER, SCHEDULER, CONTROLLER_MANAGER, STORAGE, HPA, POD, DAEMONSET, DEPLOYMENT, STATEFULSET, WORKLOADS, KUBELET, CADVISOR, DCGM and JOBSET."
  }
}

variable "network_project_id" {
  type        = string
  description = "The project ID of the shared VPC's host (for shared vpc support)"
  default     = ""
}

variable "notification_config_topic" {
  type        = string
  description = "The desired Pub/Sub topic to which notifications will be sent by GKE. Format is projects/{project}/topics/{topic}."
  default     = ""
}

variable "registry_project_ids" {
  type        = list(string)
  description = "Projects holding Google Container Registries. If empty, we use the cluster project. If a service account is created and the `grant_registry_access` variable is set to `true`, the `storage.objectViewer` and `artifactregsitry.reader` roles are assigned on these projects."
  default     = []
}

variable "release_channel" {
  type        = string
  description = "The release channel of this cluster. Accepted values are `UNSPECIFIED`, `RAPID`, `REGULAR` and `STABLE`. Defaults to `REGULAR`."
  default     = "REGULAR"
}

variable "resource_usage_export_dataset_id" {
  type        = string
  description = "The ID of a BigQuery Dataset for using BigQuery as the destination of resource usage export."
  default     = ""
}

variable "service_account" {
  type        = string
  description = "The service account to run nodes as if not overridden in `node_pools`. The create_service_account variable default value (true) will cause a cluster-specific service account to be created. This service account should already exists and it will be used by the node pools. If you wish to only override the service account name, you can use service_account_name variable."
  default     = ""
}

variable "service_account_name" {
  type        = string
  description = "The name of the service account that will be created if create_service_account is true. If you wish to use an existing service account, use service_account variable."
  default     = ""
}

variable "service_external_ips" {
  type        = bool
  description = "Whether external ips specified by a service will be allowed in this cluster"
  default     = false
}

variable "shadow_firewall_rules_log_config" {
  type = object({
    metadata = string
  })
  description = "The log_config for shadow firewall rules. You can set this variable to `null` to disable logging."
  default = {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

variable "shadow_firewall_rules_priority" {
  type        = number
  description = "The firewall priority of GKE shadow firewall rules. The priority should be less than default firewall, which is 1000."
  default     = 999
  validation {
    condition     = var.shadow_firewall_rules_priority < 1000
    error_message = "The shadow firewall rule priority must be lower than auto-created one(1000)."
  }
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

variable "network_tags" {
  description = "(Optional) - List of network tags applied to autopilot and auto-provisioned node pools."
  type        = list(string)
  default     = []
}

variable "allow_net_admin" {
  description = "(Optional) Enable NET_ADMIN for the cluster."
  type        = bool
  default     = null
}

variable "default_compute_class_enabled" {
  type        = bool
  description = "Enable default compute class for Node Auto-Provisioning"
  default     = null
}
