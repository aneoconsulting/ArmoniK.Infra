# Mode
variable "private" {
  description = "Create a private GKE cluster."
  type        = bool
  default     = true
}

# Required
variable "ip_range_pods" {
  description = "The name of the secondary subnet ip range to use for Kubernetes pods."
  type        = string
}

variable "ip_range_services" {
  description = "The name of the secondary subnet range to use for Kubernetes services."
  type        = string
}

variable "name" {
  description = "The name of the GKE cluster."
  type        = string
}

variable "network" {
  description = "The VPC network to host the GKE cluster in."
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork to host the GKE cluster in."
  type        = string
}

variable "subnetwork_cidr" {
  description = "CIDR of the subnetwork of nodes in GKE cluster."
  type        = string
}

# Optional
variable "cluster_autoscaling" {
  description = "Cluster autoscaling configuration. See [more details](https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1beta1/projects.locations.clusters#clusterautoscaling). For `disk_tye` see [Persistent Disk types](https://cloud.google.com/compute/docs/disks#disk-types)."
  type = object({
    enabled             = bool
    autoscaling_profile = string
    auto_repair         = bool
    auto_upgrade        = bool
    disk_size           = number
    disk_type           = string
    gpu_resources = list(object({
      resource_type = string
      minimum       = number
      maximum       = number
    }))
    min_cpu_cores = number
    max_cpu_cores = number
    min_memory_gb = number
    max_memory_gb = number
  })
  default = {
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
  validation {
    condition     = contains(["pd-standard", "pd-balanced", "pd-ssd", "pd-extreme"], var.cluster_autoscaling.disk_type)
    error_message = "Valid values for `cluster_autoscaling.disk_type` are: \"pd-standard\" | \"pd-balanced\" | \"pd-ssd\" | \"pd-extreme\"."
  }
  validation {
    condition = contains([
      "PROFILE_UNSPECIFIED", "OPTIMIZE_UTILIZATION", "BALANCED"
    ], var.cluster_autoscaling.autoscaling_profile)
    error_message = "Valid values for `cluster_autoscaling.autoscaling_profile` are: \"PROFILE_UNSPECIFIED\" | \"OPTIMIZE_UTILIZATION\" | \"BALANCED\"."
  }
}

variable "cluster_resource_labels" {
  description = "The GCE resource labels (a map of key/value pairs) to be applied to the cluster."
  type        = map(string)
  default     = {}
}

variable "create_service_account" {
  description = "Defines if service account specified to run nodes should be created."
  type        = bool
  default     = true
}

variable "database_encryption" {
  description = "Application-layer Secrets Encryption settings. Valid values of state are: \"ENCRYPTED\"; \"DECRYPTED\"."
  type = list(object({
    state    = string
    key_name = string
  }))
  default = [
    {
      state    = "DECRYPTED"
      key_name = ""
    }
  ]
}

variable "default_max_pods_per_node" {
  description = "The maximum number of pods to schedule per node. Note: For GKE versions earlier than 1.23.5-gke.1300, the limit is 110 Pods, otherwise the limit is 256 Pods."
  type        = number
  default     = 110
}

variable "description" {
  description = "The description of the GKE cluster."
  type        = string
  default     = ""
}

variable "enable_cost_allocation" {
  description = "Enables Cost Allocation Feature and the cluster name and namespace of your GKE workloads appear in the labels field of the billing export to BigQuery."
  type        = bool
  default     = true
}

variable "enable_resource_consumption_export" {
  description = "Whether to enable resource consumption metering on this cluster. When enabled, a table will be created in the resource export BigQuery dataset to store resource consumption data. The resulting table can be joined with the resource usage table or with BigQuery billing export."
  type        = bool
  default     = true
}

variable "enable_shielded_nodes" {
  description = "Enable Shielded Nodes features on all nodes in this cluster."
  type        = bool
  default     = true
}

variable "enable_vertical_pod_autoscaling" {
  description = "Vertical Pod Autoscaling automatically adjusts the resources of pods controlled by it."
  type        = bool
  default     = false
}

variable "filestore_csi_driver" {
  description = "The status of the Filestore CSI driver addon, which allows the usage of filestore instance as volumes."
  type        = bool
  default     = false
}

variable "gce_pd_csi_driver" {
  description = "Whether this cluster should enable the Google Compute Engine Persistent Disk Container Storage Interface (CSI) Driver."
  type        = bool
  default     = false
}

variable "gke_backup_agent_config" {
  description = "Whether Backup for GKE agent is enabled for this cluster."
  type        = bool
  default     = false
}

variable "grant_registry_access" {
  description = "Grants created cluster-specific service account `storage.objectViewer` and `artifactregistry.reader` roles."
  type        = bool
  default     = true
}

variable "horizontal_pod_autoscaling" {
  description = "Enable horizontal pod autoscaling addon."
  type        = bool
  default     = false
}

variable "initial_node_count" {
  description = "The number of nodes to create in this cluster's default node pool."
  type        = number
  default     = 0
}

variable "kubernetes_version" {
  description = "The Kubernetes version of the masters. If set to 'latest' it will pull latest available version in the selected region."
  type        = string
  default     = "latest"
}

variable "logging_enabled_components" {
  description = "List of services to monitor: SYSTEM_COMPONENTS, WORKLOADS. Empty list is default GKE configuration."
  type        = list(string)
  default     = []
  validation {
    condition     = length(setsubtract(var.logging_enabled_components, ["SYSTEM_COMPONENTS", "WORKLOADS"])) == 0
    error_message = "Valid values for `logging_enabled_components` are : \"SYSTEM_COMPONENTS\" | \"WORKLOADS\". Empty list is default GKE configuration."
  }
}

variable "master_authorized_networks" {
  description = "List of master authorized networks. If none are provided, disallow external access (except the cluster node IPs, which GKE automatically whitelists)."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "monitoring_enabled_components" {
  description = "List of services to monitor: SYSTEM_COMPONENTS, WORKLOADS (provider version >= 3.89.0). Empty list is default GKE configuration."
  type        = list(string)
  default     = []
  validation {
    condition     = length(setsubtract(var.monitoring_enabled_components, ["SYSTEM_COMPONENTS", "WORKLOADS"])) == 0
    error_message = "Valid values for `monitoring_enabled_components` are : \"SYSTEM_COMPONENTS\" | \"WORKLOADS\". Empty list is default GKE configuration."
  }
}

variable "network_policy" {
  description = "Enable network policy addon."
  type        = bool
  default     = false
}

variable "network_policy_provider" {
  description = "The network policy provider. See [more about network policy](https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy)."
  type        = string
  default     = "CALICO"
}

variable "node_metadata" {
  description = "Specifies how node metadata is exposed to the workload running on the node"
  type        = string
  default     = "GKE_METADATA"
  validation {
    condition = contains([
      "GKE_METADATA", "GCE_METADATA", "UNSPECIFIED", "GKE_METADATA_SERVER", "EXPOSE"
    ], var.node_metadata)
    error_message = "Valid values for `node_metadata` are: \"GKE_METADATA\" | \"GCE_METADATA\" | \"UNSPECIFIED\" | \"GKE_METADATA_SERVER\" | \"EXPOSE\"."
  }
}

variable "node_pools" {
  description = "List of maps containing node pools."
  type        = list(map(any))
  default = [
    {
      name = "default"
    },
  ]
}

variable "node_pools_labels" {
  description = "Map of maps containing node labels by node-pool name."
  type        = map(map(string))
  # Default is being set in variables_defaults.tf
  default = {
    all               = {}
    default-node-pool = {}
  }
}

variable "node_pools_resource_labels" {
  description = "Map of maps containing resource labels by node-pool name."
  type        = map(map(string))
  default = {
    all               = {}
    default-node-pool = {}
  }
}

variable "node_pools_tags" {
  description = "Map of lists containing node network tags by node-pool name."
  type        = map(list(string))
  # Default is being set in variables_defaults.tf
  default = {
    all               = []
    default-node-pool = []
  }
}

variable "node_pools_taints" {
  description = "Map of lists containing node taints by node-pool name."
  type = map(list(object({
    key    = string
    value  = string
    effect = string
  })))
  # Default is being set in variables_defaults.tf
  default = {
    all               = []
    default-node-pool = []
  }
}

variable "region" {
  type        = string
  description = "The region to host the cluster in (optional if zonal cluster / required if regional)"
  default     = null
}

variable "regional" {
  description = "Whether is a regional cluster (zonal cluster if set false. WARNING: changing this after cluster creation is destructive!)"
  type        = bool
  default     = true
}

variable "remove_default_node_pool" {
  description = "Remove default node pool while setting up the cluster."
  type        = bool
  default     = true
}

variable "service_account" {
  description = "The service account to run nodes as if not overridden in `node_pools`. The create_service_account variable default value (true) will cause a cluster-specific service account to be created. This service account should already exists and it will be used by the node pools. If you wish to only override the service account name, you can use service_account_name variable."
  type        = string
  default     = ""
}

variable "service_account_name" {
  description = "The name of the service account that will be created if create_service_account is true. If you wish to use an existing service account, use service_account variable."
  type        = string
  default     = ""
}

variable "windows_node_pools" {
  description = "List of maps containing Windows node pools."
  type        = list(map(string))
  default     = []
}

variable "zones" {
  description = "The zones to host the cluster in (optional if regional cluster / required if zonal)"
  type        = list(string)
  default     = []
}

variable "kubeconfig_path" {
  description = "Path to save the kubeconfig file."
  type        = string
  default     = null
}

# Optional and not used yet
variable "add_cluster_firewall_rules" {
  description = "Create additional firewall rules."
  type        = bool
  default     = false
}

variable "add_master_webhook_firewall_rules" {
  description = "Create master_webhook firewall rules for ports defined in `firewall_inbound_ports`."
  type        = bool
  default     = false
}

variable "add_shadow_firewall_rules" {
  description = "Create GKE shadow firewall (the same as default firewall rules with firewall logs enabled)."
  type        = bool
  default     = false
}

variable "authenticator_security_group" {
  description = "The name of the RBAC security group for use with Google security groups in Kubernetes RBAC. Group name must be in format `gke-security-groups@yourdomain.com`."
  type        = string
  default     = null
}

variable "cluster_dns_domain" {
  description = "The suffix used for all cluster service records."
  type        = string
  default     = ""
}

variable "cluster_dns_provider" {
  description = "Which in-cluster DNS provider should be used. PROVIDER_UNSPECIFIED (default) or PLATFORM_DEFAULT or CLOUD_DNS."
  type        = string
  default     = "PROVIDER_UNSPECIFIED"
  validation {
    condition     = contains(["PROVIDER_UNSPECIFIED", "PLATFORM_DEFAULT", "CLOUD_DNS"], var.cluster_dns_provider)
    error_message = "Valid values for `cluster_dns_provider`: \"PROVIDER_UNSPECIFIED\", \"PLATFORM_DEFAULT\", \"CLOUD_DNS\"."
  }
}

variable "cluster_dns_scope" {
  description = "The scope of access to cluster DNS records. DNS_SCOPE_UNSPECIFIED (default) or CLUSTER_SCOPE or VPC_SCOPE."
  type        = string
  default     = "DNS_SCOPE_UNSPECIFIED"
  validation {
    condition     = contains(["DNS_SCOPE_UNSPECIFIED", "CLUSTER_SCOPE", "VPC_SCOPE"], var.cluster_dns_scope)
    error_message = "Valid values for `cluster_dns_scope`: \"DNS_SCOPE_UNSPECIFIED\", \"CLUSTER_SCOPE\", \"VPC_SCOPE\"."
  }
}

variable "cluster_ipv4_cidr" {
  description = "The IP address range of the Kubernetes pods in this cluster. Default is an automatically assigned CIDR."
  type        = string
  default     = null
}

variable "configure_ip_masq" {
  description = "Enables the installation of ip masquerading, which is usually no longer required when using aliasied IP addresses. IP masquerading uses a kubectl call, so when you have a private cluster, you will need access to the API server."
  type        = bool
  default     = false
}

variable "datapath_provider" {
  description = "The desired datapath provider for this cluster. By default, `DATAPATH_PROVIDER_UNSPECIFIED` enables the IPTables-based kube-proxy implementation. `ADVANCED_DATAPATH` enables Dataplane-V2 feature."
  type        = string
  default     = "DATAPATH_PROVIDER_UNSPECIFIED"
  validation {
    condition     = contains(["DATAPATH_PROVIDER_UNSPECIFIED", "ADVANCED_DATAPATH"], var.datapath_provider)
    error_message = "Valid values for `datapath_provider`: \"DATAPATH_PROVIDER_UNSPECIFIED\" | \"ADVANCED_DATAPATH\"."
  }
}

variable "disable_default_snat" {
  description = "Whether to disable the default SNAT to support the private use of public IP addresses"
  type        = bool
  default     = false
}

variable "disable_legacy_metadata_endpoints" {
  description = "Disable the /0.1/ and /v1beta1/ metadata server endpoints on the node. Changing this value will cause all node pools to be recreated."
  type        = bool
  default     = true
}

variable "dns_cache" {
  description = "The status of the NodeLocal DNSCache addon."
  type        = bool
  default     = false
}

variable "enable_binary_authorization" {
  description = "Enable BinAuthZ Admission controller."
  type        = bool
  default     = false
}

variable "enable_kubernetes_alpha" {
  description = "Whether to enable Kubernetes Alpha features for this cluster. Note that when this option is enabled, the cluster cannot be upgraded and will be automatically deleted after 30 days."
  type        = bool
  default     = false
}

variable "enable_network_egress_export" {
  description = "Whether to enable network egress metering for this cluster. If enabled, a daemonset will be created in the cluster to meter network egress traffic."
  type        = bool
  default     = false
}

variable "firewall_inbound_ports" {
  description = "List of TCP ports for admission/webhook controllers. Either flag `add_master_webhook_firewall_rules` or `add_cluster_firewall_rules` (also adds egress rules) must be set to `true` for inbound-ports firewall rules to be applied."
  type        = list(string)
  default     = ["8443", "9443", "15017"]
}

variable "firewall_priority" {
  description = "Priority rule for firewall rules."
  type        = number
  default     = 1000
}

variable "gateway_api_channel" {
  description = "The gateway api channel of this cluster. Accepted values are `CHANNEL_STANDARD` and `CHANNEL_DISABLED`."
  type        = string
  default     = null
  validation {
    condition = contains([
      "CHANNEL_STANDARD", "CHANNEL_DISABLED"
    ], coalesce(var.gateway_api_channel, "CHANNEL_STANDARD"))
    error_message = "Valid values for `gateway_api_channel`: \"CHANNEL_STANDARD\" | \"CHANNEL_DISABLED\"."
  }
}

variable "http_load_balancing" {
  description = "Enable httpload balancer addon."
  type        = bool
  default     = true
}

variable "identity_namespace" {
  description = "The workload pool to attach all Kubernetes service accounts to. (Default value of `enabled` automatically sets project-based pool `[project_id].svc.id.goog`)"
  type        = string
  default     = "enabled"
}

variable "ip_masq_link_local" {
  description = "Whether to masquerade traffic to the link-local prefix (169.254.0.0/16)."
  type        = bool
  default     = false
}

variable "ip_masq_resync_interval" {
  description = "The interval at which the agent attempts to sync its ConfigMap file from the disk."
  type        = string
  default     = "60s"
}

variable "issue_client_certificate" {
  description = "Issues a client certificate to authenticate to the cluster endpoint. To maximize the security of your cluster, leave this option disabled. Client certificates don't automatically rotate and aren't easily revocable. WARNING: changing this after cluster creation is destructive!"
  type        = bool
  default     = false
}

variable "logging_service" {
  description = "The logging service that the cluster should write logs to. Available options include logging.googleapis.com, logging.googleapis.com/kubernetes (beta), and none"
  type        = string
  default     = "logging.googleapis.com/kubernetes"
  validation {
    condition     = contains(["logging.googleapis.com", "logging.googleapis.com/kubernetes", "none"], var.logging_service)
    error_message = "Valid values for `logging_service`: \"logging.googleapis.com\" | \"logging.googleapis.com/kubernetes\" | \"none\"."
  }
}

variable "maintenance_end_time" {
  description = "Time window specified for recurring maintenance operations in RFC3339 format."
  type        = string
  default     = ""
}

variable "maintenance_exclusions" {
  description = "List of maintenance exclusions. A cluster can have up to three"
  type = list(object({
    name            = string
    start_time      = string
    end_time        = string
    exclusion_scope = string
  }))
  default = []
}

variable "maintenance_recurrence" {
  description = "Frequency of the recurring maintenance window in RFC5545 format."
  type        = string
  default     = ""
}

variable "maintenance_start_time" {
  description = "Time window specified for daily or recurring maintenance operations in RFC3339 format."
  type        = string
  default     = "05:00"
}

variable "monitoring_enable_managed_prometheus" {
  description = "Configuration for Managed Service for Prometheus. Whether or not the managed collection is enabled."
  type        = bool
  default     = false
}

variable "monitoring_service" {
  description = "The monitoring service that the cluster should write metrics to. Automatically send metrics from pods in the cluster to the Google Cloud Monitoring API. VM metrics will be collected by Google Compute Engine regardless of this setting Available options include monitoring.googleapis.com, monitoring.googleapis.com/kubernetes (beta) and none"
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
  validation {
    condition = contains([
      "monitoring.googleapis.com/kubernetes", "monitoring.googleapis.com", "none"
    ], var.monitoring_service)
    error_message = "Valid values for `monitoring_service`: \"monitoring.googleapis.com/kubernetes\" | \"monitoring.googleapis.com\" | \"none\"."
  }
}

variable "network_project_id" {
  description = "The project ID of the shared VPC's host (for shared vpc support)."
  type        = string
  default     = ""
}

variable "node_pools_linux_node_configs_sysctls" {
  description = "Map of maps containing linux node config sysctls by node-pool name."
  type        = map(map(string))
  # Default is being set in variables_defaults.tf
  default = {
    all               = {}
    default-node-pool = {}
  }
}

variable "node_pools_metadata" {
  type        = map(map(string))
  description = "Map of maps containing node metadata by node-pool name"
  # Default is being set in variables_defaults.tf
  default = {
    all               = {}
    default-node-pool = {}
  }
}

variable "node_pools_oauth_scopes" {
  description = "Map of lists containing node oauth scopes by node-pool name."
  type        = map(list(string))
  # Default is being set in variables_defaults.tf
  default = {
    all               = ["https://www.googleapis.com/auth/cloud-platform"]
    default-node-pool = []
  }
}

variable "non_masquerade_cidrs" {
  description = "List of strings in CIDR notation that specify the IP address ranges that do not use IP masquerading."
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "notification_config_topic" {
  description = "The desired Pub/Sub topic to which notifications will be sent by GKE. Format is projects/{project}/topics/{topic}."
  type        = string
  default     = ""
}

variable "registry_project_ids" {
  description = "Projects holding Google Container Registries. If empty, we use the cluster project. If a service account is created and the `grant_registry_access` variable is set to `true`, the `storage.objectViewer` and `artifactregsitry.reader` roles are assigned on these projects."
  type        = list(string)
  default     = []
}

variable "release_channel" {
  description = "The release channel of this cluster. This allows you to opt for the alpha releases as part of the `RAPID` option, `REGULAR` for standard release needs and `STABLE` when the tried-and-tested version becomes available."
  type        = string
  default     = "REGULAR"
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE", "UNSPECIFIED"], var.release_channel)
    error_message = "Valid values for `release_channel`: \"RAPID\" | \"REGULAR\" | \"STABLE\", | \"UNSPECIFIED\"."
  }
}

variable "resource_usage_export_dataset_id" {
  description = "The ID of a BigQuery Dataset for using BigQuery as the destination of resource usage export."
  type        = string
  default     = ""
}

variable "service_external_ips" {
  description = "Whether external ips specified by a service will be allowed in this cluster."
  type        = bool
  default     = false
}

variable "shadow_firewall_rules_log_config" {
  description = "The log_config for shadow firewall rules. You can set this variable to `null` to disable logging."
  type = object({
    metadata = string
  })
  default = {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

variable "shadow_firewall_rules_priority" {
  description = "The firewall priority of GKE shadow firewall rules. The priority should be less than default firewall, which is 1000."
  type        = number
  default     = 999
  validation {
    condition     = var.shadow_firewall_rules_priority < 1000
    error_message = "The shadow firewall rule priority must be lower than auto-created one(1000)."
  }
}

variable "stub_domains" {
  description = "Map of stub domains and their resolvers to forward DNS queries for a certain domain to an external DNS server."
  type        = map(list(string))
  default     = {}
}

variable "timeouts" {
  description = "Timeout for cluster operations."
  type        = map(string)
  default     = {}
  validation {
    condition     = alltrue([for key in keys(var.timeouts) : contains(["create", "update", "delete"], key)])
    error_message = "Only create, update, delete timeouts can be specified."
  }
}

variable "upstream_nameservers" {
  description = "If specified, the values replace the nameservers taken by default from the node’s /etc/resolv.conf."
  type        = list(string)
  default     = []
}

# Optional for beta GKE
variable "cloudrun" {
  description = "(Beta) Enable CloudRun addon."
  type        = bool
  default     = false
}

variable "cloudrun_load_balancer_type" {
  description = "(Beta) Configure the Cloud Run load balancer type. External by default. Set to `LOAD_BALANCER_TYPE_INTERNAL` to configure as an internal load balancer."
  type        = string
  default     = ""
  validation {
    condition = contains([
      "LOAD_BALANCER_TYPE_INTERNAL"
    ], coalesce(var.cloudrun_load_balancer_type, "LOAD_BALANCER_TYPE_INTERNAL"))
    error_message = "Valid values for `cloudrun_load_balancer_type` are: \"LOAD_BALANCER_TYPE_INTERNAL\" if internal, otherwise is External by default."
  }
}

variable "cluster_telemetry_type" {
  description = "Available options include ENABLED, DISABLED, and SYSTEM_ONLY."
  type        = string
  default     = null
  validation {
    condition     = contains(["ENABLED", "DISABLED", "SYSTEM_ONLY"], coalesce(var.cluster_telemetry_type, "ENABLED"))
    error_message = "Valid values for `cluster_telemetry_type` are: \"ENABLED\" | \"DISABLED\" | \"SYSTEM_ONLY\"."
  }
}

variable "config_connector" {
  description = "(Beta) Whether ConfigConnector is enabled for this cluster."
  type        = bool
  default     = false
}

variable "enable_confidential_nodes" {
  description = "An optional flag to enable confidential node config."
  type        = bool
  default     = false
}

variable "enable_identity_service" {
  description = "Enable the Identity Service component, which allows customers to use external identity providers with the K8S API."
  type        = bool
  default     = false
}

variable "enable_intranode_visibility" {
  description = "Whether Intra-node visibility is enabled for this cluster. This makes same node pod to pod traffic visible for VPC network."
  type        = bool
  default     = false
}

variable "enable_l4_ilb_subsetting" {
  description = "Enable L4 ILB Subsetting on the cluster.  Used when `beta` set to `true`."
  type        = bool
  default     = false
}

variable "enable_pod_security_policy" {
  description = "enabled - Enable the PodSecurityPolicy controller for this cluster. If enabled, pods must be valid under a PodSecurityPolicy to be created. Pod Security Policy was removed from GKE clusters with version >= 1.25.0.Used when `beta` set to `true`."
  type        = bool
  default     = false
}

variable "enable_tpu" {
  description = "Enable Cloud TPU resources in the cluster. WARNING: changing this after cluster creation is destructive! Used when `beta` set to `true`."
  type        = bool
  default     = false
}

variable "istio" {
  description = "(Beta) Enable Istio addon."
  type        = bool
  default     = false
}

variable "istio_auth" {
  type        = string
  description = "(Beta) The authentication type between services in Istio."
  default     = "AUTH_MUTUAL_TLS"
  validation {
    condition     = contains(["AUTH_MUTUAL_TLS"], coalesce(var.istio_auth, "AUTH_MUTUAL_TLS"))
    error_message = "Valid values for `istio_auth` are: \"AUTH_MUTUAL_TLS\"."
  }
}

variable "kalm_config" {
  description = "(Beta) Whether KALM is enabled for this cluster."
  type        = bool
  default     = false
}

variable "sandbox_enabled" {
  description = "(Beta) Enable GKE Sandbox (Do not forget to set `image_type` = `COS_CONTAINERD` to use it)."
  type        = bool
  default     = false
}

variable "workload_config_audit_mode" {
  description = "(beta) Worload config audit mode."
  type        = string
  default     = "DISABLED"
  validation {
    condition     = contains(["DISABLED", "BASIC"], var.workload_config_audit_mode)
    error_message = "Valid values for `workload_config_audit_mode` are: \"DISABLED\" | \"BASIC\"."
  }
}

variable "workload_vulnerability_mode" {
  description = "(beta) Vulnerability mode."
  type        = string
  default     = ""
  validation {
    condition     = contains(["DISABLED", "BASIC"], coalesce(var.workload_vulnerability_mode, "DISABLED"))
    error_message = "Valid values for `workload_vulnerability_mode` are: \"DISABLED\" | \"BASIC\"."
  }
}

# Optional for private GKE
variable "deploy_using_private_endpoint" {
  description = "(Beta) A toggle for Terraform and kubectl to connect to the master's internal IP address during deployment. Used when `private` set to `true`."
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "(Beta) The IP range in CIDR notation to use for the hosted master network. Used when `private` set to `true`."
  type        = string
  default     = "10.0.0.0/28"
}

variable "master_global_access_enabled" {
  description = "Whether the cluster master is accessible globally (from any region) or only within the same region as the private endpoint. Used when `private` set to `true`."
  type        = bool
  default     = true
}
