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

variable "regional" {
  description = "Create a regional cluster, or a zonal one in \"zone\". Changing it recreates the cluster."
  type        = bool
  default     = true
  nullable    = false
}

variable "region" {
  description = "Region of a regional cluster. Defaults to the provider region; ignored for a zonal cluster, whose region is the one of its zone."
  type        = string
  default     = null
}

variable "zone" {
  description = "Zone of a zonal cluster, required then; ignored for a regional cluster. Changing it recreates the cluster."
  type        = string
  default     = null
}

variable "zones" {
  description = "Zones of the nodes. Regional cluster: three zones of the region chosen by GKE by default. Zonal cluster: more zones besides \"zone\", none by default."
  type        = set(string)
  default     = []
  nullable    = false
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

variable "additional_ip_ranges_pods" {
  description = "Names of more secondary ranges of the subnetwork for the Pods, to grow the cluster without recreating it."
  type        = list(string)
  default     = []
  nullable    = false
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

variable "deletion_protection" {
  description = "Refuse the deletion of the cluster by Terraform."
  type        = bool
  default     = true
  nullable    = false
}

variable "labels" {
  description = "Labels of the cluster and of the nodes of its node pools."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "kms_key" {
  description = "Cloud KMS key, in the region of the cluster, that encrypts the Kubernetes secrets in etcd. An object, so that the key can be created in the same apply: its ID is unknown at plan time, the object is not."
  type = object({
    id = string
  })
  default = null
}

variable "boot_disk_kms_key" {
  description = "Cloud KMS key, in the region of the cluster, that encrypts the boot disks of the nodes, auto-provisioned ones included. An object for the same reason as \"kms_key\"."
  type = object({
    id = string
  })
  default = null
}

variable "service_account" {
  description = "Email of an existing service account for the nodes. Null: the module creates one with the \"service_account_roles\"."
  type        = string
  default     = null
}

variable "service_account_name" {
  description = "Account ID of the node service account the module creates. Defaults to gke-<first 20 characters of the name>-nodes."
  type        = string
  default     = null
}

variable "service_account_roles" {
  description = "Project roles of the node service account the module creates. Without roles/container.defaultNodeServiceAccount, the nodes cannot write their logs and metrics."
  type        = set(string)
  default     = ["roles/container.defaultNodeServiceAccount"]
  nullable    = false
}

variable "grant_registry_access" {
  description = "Grant the Artifact Registry reader role to the node service account the module creates, on the project and on \"registry_project_ids\"."
  type        = bool
  default     = true
  nullable    = false
}

variable "registry_project_ids" {
  description = "More projects whose Artifact Registry the nodes read from, with \"grant_registry_access\"."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "fleet_project" {
  description = "Project of the fleet to register the cluster in. Null: not registered."
  type        = string
  default     = null
}

variable "kubeconfig_path" {
  description = "Path of a kubeconfig file dedicated to the cluster, managed by Terraform and replaced whole. Null: no file."
  type        = string
  default     = null
}

variable "control_plane" {
  description = <<-EOT
    Access to the control plane.
    * enable_private_endpoint: no public IP endpoint, only the private one in the VPC. Requires private nodes.
    * enable_ip_endpoint: false leaves the DNS endpoint only, authenticated by IAM, with no IP to protect.
    * master_ipv4_cidr_block: /28 range of the private endpoint. GKE takes an IP of the node subnetwork by default.
      Permanent, and unique in the VPC.
    * global_access: the private endpoint is reachable from every region of the VPC.
    * authorized_networks: CIDR blocks allowed to reach the IP endpoints, besides the nodes. Empty: no external IP
      reaches the public endpoint.
    * authorized_networks_on_private_endpoint: also enforce them on the private endpoint, so that a VM of the VPC outside
      the node subnetwork, a bastion for one, has to be listed.
    * dns_allow_external_traffic: the DNS endpoint accepts IAM-authenticated calls from outside the VPC.
  EOT
  type = object({
    enable_private_endpoint = optional(bool, true)
    enable_ip_endpoint      = optional(bool, true)
    master_ipv4_cidr_block  = optional(string)
    global_access           = optional(bool, true)
    authorized_networks = optional(list(object({
      cidr_block   = string
      display_name = optional(string)
    })), [])
    authorized_networks_on_private_endpoint = optional(bool, true)
    dns_allow_external_traffic              = optional(bool, false)
  })
  default  = {}
  nullable = false
}

variable "networking" {
  description = <<-EOT
    Networking of the cluster.
    * dataplane_v2: Dataplane V2 (ADVANCED_DATAPATH: eBPF, no kube-proxy), which always enforces the network policies.
      false: the legacy datapath (LEGACY_DATAPATH, kube-proxy). Changing it recreates the cluster.
    * network_policy: the network policies are enforced. Requires dataplane_v2 or calico: the legacy datapath alone
      ignores them silently.
    * calico: legacy datapath only, enforce the network policies with Calico.
    * enable_private_nodes: nodes get internal IP addresses only and reach the internet through Cloud NAT.
    * default_max_pods_per_node: sizes the Pod range of each node. Changing it recreates the cluster.
    * disable_default_snat: keep the Pod IP behind Cloud NAT, or use public IP ranges privately.
    * cloud_dns: Cloud DNS in cluster scope instead of kube-dns, which no longer has to scale with the nodes.
    * cluster_dns_domain, additive_vpc_scope_dns_domain: Cloud DNS only.
    * dns_cache: NodeLocal DNSCache on every node.
    * gateway_api: install the Gateway API CRDs of the standard channel, managed by GKE, and the GKE Gateway controller.
    * service_external_ips: allow spec.externalIPs on Services.
    * fqdn_network_policy, cilium_clusterwide_network_policy: the matching Dataplane V2 policy kinds.
    * in_transit_encryption: transparent encryption of the traffic between nodes, Dataplane V2 only.
    * intranode_visibility, l4_ilb_subsetting: as the GKE options of the same name.
  EOT
  type = object({
    dataplane_v2 = optional(bool, true)
    # True by default: Dataplane V2 always enforces them, and leaving it forces a choice between calico and false
    network_policy                    = optional(bool, true)
    calico                            = optional(bool, false)
    enable_private_nodes              = optional(bool, true)
    default_max_pods_per_node         = optional(number, 110)
    disable_default_snat              = optional(bool, false)
    cloud_dns                         = optional(bool, true)
    cluster_dns_domain                = optional(string)
    additive_vpc_scope_dns_domain     = optional(string)
    dns_cache                         = optional(bool, true)
    gateway_api                       = optional(bool, true)
    service_external_ips              = optional(bool, false)
    fqdn_network_policy               = optional(bool, false)
    cilium_clusterwide_network_policy = optional(bool, false)
    in_transit_encryption             = optional(bool, false)
    intranode_visibility              = optional(bool, false)
    l4_ilb_subsetting                 = optional(bool, false)
  })
  default  = {}
  nullable = false
  validation {
    condition     = !(var.networking.calico && var.networking.dataplane_v2)
    error_message = "\"networking.calico\" requires \"networking.dataplane_v2\" = false: Dataplane V2 enforces the network policies itself."
  }
  validation {
    condition     = !var.networking.network_policy || var.networking.dataplane_v2 || var.networking.calico
    error_message = "\"networking.network_policy\" requires \"networking.dataplane_v2\" or \"networking.calico\": the legacy datapath alone ignores the network policies."
  }
}

variable "autoscaling" {
  description = <<-EOT
    Cluster autoscaling.
    * profile: OPTIMIZE_UTILIZATION removes the underused nodes faster than BALANCED. Pods that must not be evicted
      carry the cluster-autoscaler.kubernetes.io/safe-to-evict: "false" annotation.
    * hpa_profile: PERFORMANCE allows more HorizontalPodAutoscalers per cluster, KEDA creating one per ScaledObject,
      and collects their metrics faster. NONE opts out.
    * default_compute_class: let a ComputeClass named "default" apply to the Pods that select none. The ComputeClasses
      are Kubernetes objects, applied apart from this module (with the workloads they place).
    * node_auto_provisioning: null disables it. Limits are over the whole cluster. The nodes it creates use the node
      service account and the boot disk key of the module. ComputeClasses with nodePoolAutoCreation create node pools
      without it on GKE 1.33.3-gke.1136000 and later; they set their service account themselves. Required without any
      node pool: the Pods that select no ComputeClass (kube-system first) would find no node.
  EOT
  type = object({
    profile               = optional(string, "OPTIMIZE_UTILIZATION")
    hpa_profile           = optional(string, "PERFORMANCE")
    default_compute_class = optional(bool, true)
    node_auto_provisioning = optional(object({
      min_cpu_cores = optional(number, 0)
      max_cpu_cores = number
      min_memory_gb = optional(number, 0)
      max_memory_gb = number
      gpu_resources = optional(list(object({
        resource_type = string
        minimum       = optional(number, 0)
        maximum       = number
      })), [])
      locations        = optional(list(string))
      image_type       = optional(string, "COS_CONTAINERD")
      disk_type        = optional(string, "pd-balanced")
      disk_size_gb     = optional(number, 100)
      min_cpu_platform = optional(string)
    }))
  })
  default  = {}
  nullable = false
  validation {
    condition     = contains(["OPTIMIZE_UTILIZATION", "BALANCED"], var.autoscaling.profile)
    error_message = "Valid values for \"autoscaling.profile\" are: \"OPTIMIZE_UTILIZATION\" | \"BALANCED\"."
  }
  validation {
    condition     = contains(["PERFORMANCE", "NONE"], var.autoscaling.hpa_profile)
    error_message = "Valid values for \"autoscaling.hpa_profile\" are: \"PERFORMANCE\" | \"NONE\"."
  }
}

variable "node_pools" {
  description = <<-EOT
    Static node pools keyed by name, next to the ones that ComputeClasses create. The default is a "system" pool for the
    Pods that select no ComputeClass. Empty: every node comes from node auto-provisioning or from the ComputeClasses,
    which requires "autoscaling.node_auto_provisioning". The defaults below apply to an attribute left unset.
    * Size: autoscaling between min_count and max_count nodes per zone, or between total_min_count and total_max_count
      over all the zones of the pool when both are set; a fixed node_count per zone disables autoscaling. location_policy
      ANY suits Spot VMs.
    * Provisioning: spot, flex_start (Dynamic Workload Scheduler), max_run_duration ("3600s"), queued_provisioning,
      best_effort_min_nodes, reservation_affinity, placement_policy ("COMPACT", low latency between nodes).
      flex_start and queued_provisioning (which requires flex_start) go with autoscaling, location_policy ANY, no Spot
      VM and no reservation, and turn off auto-repair.
    * Disks: disk_type pd-balanced by default, hyperdisk-balanced on the machine families that only support Hyperdisk
      (C4, C4D, N4); local SSDs as raw scratch (local_ssd_count), as ephemeral storage (ephemeral_local_ssd_count) or as
      raw block devices (local_nvme_ssd_block_count); secondary_boot_disks preload container images.
    * Startup: image_streaming and gvnic, on by default.
    * Compute: gpu (with driver installation and sharing), threads_per_core (1 disables SMT), sandbox (gVisor),
      confidential_instance_type (SEV, SEV_SNP, TDX), kubelet and linux node settings.
    * upgrade: SURGE (max_surge, max_unavailable) or BLUE_GREEN (node_pool_soak_duration, batch_percentage,
      batch_soak_duration); drain: node drain settings.
  EOT
  type = map(object({
    machine_type               = optional(string, "e2-medium")
    image_type                 = optional(string, "COS_CONTAINERD")
    min_cpu_platform           = optional(string)
    node_locations             = optional(list(string))
    service_account            = optional(string)
    min_count                  = optional(number, 1)
    max_count                  = optional(number, 100)
    total_min_count            = optional(number)
    total_max_count            = optional(number)
    location_policy            = optional(string)
    node_count                 = optional(number)
    initial_node_count         = optional(number)
    max_pods_per_node          = optional(number)
    pod_range                  = optional(string)
    tier_1_networking          = optional(bool, false)
    spot                       = optional(bool, false)
    flex_start                 = optional(bool, false)
    max_run_duration           = optional(string)
    queued_provisioning        = optional(bool, false)
    best_effort_min_nodes      = optional(number)
    placement_policy           = optional(string)
    disk_type                  = optional(string, "pd-balanced")
    disk_size_gb               = optional(number, 100)
    local_ssd_count            = optional(number)
    ephemeral_local_ssd_count  = optional(number)
    local_nvme_ssd_block_count = optional(number)
    secondary_boot_disks = optional(list(object({
      disk_image = string
      mode       = optional(string)
    })), [])
    image_streaming            = optional(bool, true)
    gvnic                      = optional(bool, true)
    logging_variant            = optional(string)
    secure_boot                = optional(bool, true)
    sandbox                    = optional(bool, false)
    confidential_instance_type = optional(string)
    threads_per_core           = optional(number)
    gpu = optional(object({
      type                       = string
      count                      = number
      driver_version             = optional(string, "DEFAULT")
      partition_size             = optional(string)
      sharing_strategy           = optional(string)
      max_shared_clients_per_gpu = optional(number)
    }))
    reservation_affinity = optional(object({
      type   = string
      key    = optional(string)
      values = optional(list(string))
    }))
    kubelet = optional(object({
      cpu_manager_policy                          = optional(string)
      cpu_cfs_quota                               = optional(bool)
      cpu_cfs_quota_period                        = optional(string)
      pod_pids_limit                              = optional(number)
      max_parallel_image_pulls                    = optional(number)
      image_gc_high_threshold_percent             = optional(number)
      image_gc_low_threshold_percent              = optional(number)
      container_log_max_size                      = optional(string)
      container_log_max_files                     = optional(number)
      single_process_oom_kill                     = optional(bool)
      shutdown_grace_period_seconds               = optional(number)
      shutdown_grace_period_critical_pods_seconds = optional(number)
      allowed_unsafe_sysctls                      = optional(list(string))
      topology_manager_policy                     = optional(string)
      topology_manager_scope                      = optional(string)
      memory_manager_policy                       = optional(string)
    }), {})
    linux = optional(object({
      cgroup_mode                  = optional(string, "CGROUP_MODE_V2")
      sysctls                      = optional(map(string), {})
      hugepages_2m                 = optional(number)
      hugepages_1g                 = optional(number)
      transparent_hugepage_enabled = optional(string)
      transparent_hugepage_defrag  = optional(string)
    }), {})
    upgrade = optional(object({
      strategy                = optional(string, "SURGE")
      max_surge               = optional(number, 1)
      max_unavailable         = optional(number, 0)
      node_pool_soak_duration = optional(string)
      batch_percentage        = optional(number)
      batch_soak_duration     = optional(string)
    }), {})
    drain = optional(object({
      grace_termination_duration            = optional(string)
      pdb_timeout_duration                  = optional(string)
      respect_pdb_during_node_pool_deletion = optional(bool)
    }))
    labels          = optional(map(string), {})
    resource_labels = optional(map(string), {})
    tags            = optional(list(string), [])
    metadata        = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  # The default goes through the type above, which fills in the optional attributes. A default built in the
  # module instead (coalesce) would be unified with this type into a map of strings, dropping them.
  # A small pool for the Pods that select no ComputeClass (kube-system, webhooks, operators): they get nodes from the
  # first apply and are not moved around by the node pools that the ComputeClasses create and remove.
  default = {
    system = {
      machine_type = "e2-standard-4"
      min_count    = 1
      max_count    = 3
    }
  }
  nullable = false
  validation {
    condition     = alltrue([for pool in values(var.node_pools) : (pool.total_min_count == null) == (pool.total_max_count == null)])
    error_message = "\"total_min_count\" and \"total_max_count\" of a node pool must be set together."
  }
  validation {
    condition     = alltrue([for pool in values(var.node_pools) : contains(["SURGE", "BLUE_GREEN"], pool.upgrade.strategy)])
    error_message = "Valid values for \"upgrade.strategy\" of a node pool are: \"SURGE\" | \"BLUE_GREEN\"."
  }
  validation {
    condition     = alltrue([for pool in values(var.node_pools) : pool.upgrade.strategy != "BLUE_GREEN" || pool.upgrade.node_pool_soak_duration != null])
    error_message = "A BLUE_GREEN upgrade of a node pool requires \"upgrade.node_pool_soak_duration\"."
  }
  validation {
    condition     = alltrue([for pool in values(var.node_pools) : !pool.queued_provisioning || pool.flex_start])
    error_message = "\"queued_provisioning\" of a node pool requires \"flex_start\"."
  }
  validation {
    condition = alltrue([for pool in values(var.node_pools) : !pool.flex_start || (
      pool.node_count == null && pool.location_policy == "ANY" && !pool.spot && try(pool.reservation_affinity.type, "NO_RESERVATION") == "NO_RESERVATION"
    )])
    error_message = "A \"flex_start\" node pool requires autoscaling (no \"node_count\"), \"location_policy\" ANY, no \"spot\" and no \"reservation_affinity\" other than NO_RESERVATION."
  }
  validation {
    condition     = alltrue(flatten([for pool in values(var.node_pools) : [for taint in pool.taints : contains(["NO_SCHEDULE", "PREFER_NO_SCHEDULE", "NO_EXECUTE"], taint.effect)]]))
    error_message = "Valid values for the effect of a taint are: \"NO_SCHEDULE\" | \"PREFER_NO_SCHEDULE\" | \"NO_EXECUTE\"."
  }
}

variable "addons" {
  description = "GKE add-ons. The Compute Engine persistent disk CSI driver is always on."
  type = object({
    http_load_balancing        = optional(bool, true)
    horizontal_pod_autoscaling = optional(bool, true)
    vertical_pod_autoscaling   = optional(bool, false)
    filestore_csi_driver       = optional(bool, false)
    gcs_fuse_csi_driver        = optional(bool, false)
    lustre_csi_driver          = optional(bool, false)
    backup_agent               = optional(bool, false)
    config_connector           = optional(bool, false)
    stateful_ha                = optional(bool, false)
  })
  default  = {}
  nullable = false
}

variable "security" {
  description = <<-EOT
    Security options. Anonymous authentication limited to the health checks, the insecure system RBAC bindings, the
    kubelet read-only port, the legacy metadata endpoints and the client certificates are always off.
    * posture_mode, vulnerability_mode: security posture dashboard and workload vulnerability scanning. Null: GKE default.
    * binary_authorization: evaluation mode, PROJECT_SINGLETON_POLICY_ENFORCE for one. Null: off.
    * security_group: Google Group gke-security-groups@<domain> for Kubernetes RBAC on Google Groups.
    * identity_service: authentication through third-party identity providers.
    * secret_manager: Secret Manager add-on, mounting secrets as CSI volumes.
    * shielded_nodes: the nodes prove their identity to the control plane before joining it.
  EOT
  type = object({
    posture_mode         = optional(string, "BASIC")
    vulnerability_mode   = optional(string)
    binary_authorization = optional(string)
    security_group       = optional(string)
    identity_service     = optional(bool, false)
    secret_manager       = optional(bool, false)
    shielded_nodes       = optional(bool, true)
  })
  default  = {}
  nullable = false
}

variable "observability" {
  description = <<-EOT
    Logs, metrics and cost.
    * logging_components, monitoring_components: sent to Cloud Logging and Cloud Monitoring. Null: GKE default, which
      sends the workload logs to Cloud Logging, billed by volume.
    * logging_variant: DEFAULT, or MAX_THROUGHPUT for nodes writing many logs.
    * managed_prometheus: Google Cloud Managed Service for Prometheus collection.
    * dataplane_v2_metrics, dataplane_v2_relay: Dataplane V2 observability metrics, and the Hubble relay. Dataplane V2
      only.
    * cost_allocation: cluster and namespace of the workloads in the billing export.
    * usage_export_dataset: BigQuery dataset of the resource consumption metering; network_egress_metering adds a
      DaemonSet metering the egress.
  EOT
  type = object({
    logging_components      = optional(list(string))
    monitoring_components   = optional(list(string))
    logging_variant         = optional(string, "DEFAULT")
    managed_prometheus      = optional(bool, false)
    dataplane_v2_metrics    = optional(bool, false)
    dataplane_v2_relay      = optional(bool, false)
    cost_allocation         = optional(bool, true)
    usage_export_dataset    = optional(string)
    network_egress_metering = optional(bool, false)
  })
  default  = {}
  nullable = false
}

variable "maintenance" {
  description = <<-EOT
    Upgrades of the cluster.
    * start_time, end_time, recurrence: without recurrence, a daily window starting at start_time (HH:MM, UTC). With
      recurrence (RFC 5545 RRULE), start_time and end_time are RFC 3339 dates.
    * exclusions: windows without upgrades of the given scope: NO_UPGRADES, NO_MINOR_UPGRADES or
      NO_MINOR_OR_NODE_UPGRADES.
    * patch_mode: ACCELERATED upgrades to the latest patch of the minor version as soon as it is out.
    * rollback_soak_duration: upgrade the control plane in two steps, rollbackable for this duration ("86400s").
    * notification_topic: Pub/Sub topic (projects/<project>/topics/<topic>) of the upgrade notifications.
  EOT
  type = object({
    start_time = optional(string, "05:00")
    end_time   = optional(string)
    recurrence = optional(string)
    exclusions = optional(list(object({
      name       = string
      start_time = string
      end_time   = string
      scope      = optional(string, "NO_UPGRADES")
    })), [])
    patch_mode             = optional(string)
    rollback_soak_duration = optional(string)
    notification_topic     = optional(string)
  })
  default  = {}
  nullable = false
  validation {
    condition     = (var.maintenance.end_time == null) == (var.maintenance.recurrence == null)
    error_message = "\"maintenance.end_time\" and \"maintenance.recurrence\" go together."
  }
}
