# Profile
variable "profile" {
  description = "Profile of AWS credentials to deploy Terraform sources"
  type        = string
}

# Kubeconfig file path
variable "kubeconfig_file" {
  description = "Kubeconfig file path"
  type        = string
}

# Tags
variable "tags" {
  description = "Tags for resource"
  type        = map(string)
  default     = {}
}

# EKS name
variable "name" {
  description = "AWS EKS service name"
  type        = string
  default     = "armonik-eks"
}

variable "region" {
  description = "AWS region where the EKS resources will be managed. Defaults to the region set in the provider configuration"
  type        = string
  default     = null
}

# Node selector
variable "node_selector" {
  description = "Node selector for pods of EKS system"
  type        = any
  default     = {}
}

# EKS
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster "
  type        = string
}

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
}

variable "cluster_log_retention_in_days" {
  description = "Logs retention in days"
  type        = number
}

variable "cluster_deletion_protection" {
  description = "Whether to enable deletion protection for the cluster; it must be disabled before the cluster can be deleted"
  type        = bool
  default     = null
}

variable "cluster_kms_key_rotation_period_in_days" {
  description = "Period in days between two rotations of the KMS key created for secret encryption, between 90 and 2560. Defaults to 365"
  type        = number
  default     = null
}

variable "cluster_control_plane_scaling_config" {
  description = "EKS Provisioned Control Plane scaling tier. Valid values for tier are `standard`, `tier-xl`, `tier-2xl`, `tier-4xl` and `tier-8xl`"
  type = object({
    tier = string
  })
  default = null
}

variable "cluster_control_plane_egress_mode" {
  description = "Egress mode for the EKS control plane. Valid values are `AWS_MANAGED` and `CUSTOMER_ROUTED`"
  type        = string
  default     = null
}

variable "cluster_kube_api_server_config" {
  description = "Configuration of the Kubernetes API server"
  type = object({
    event_ttl = optional(string)
    service_node_port_range = optional(object({
      min_port = optional(number)
      max_port = optional(number)
    }))
  })
  default = null
}

variable "cluster_kube_controller_manager_config" {
  description = "Configuration of the Kubernetes controller manager"
  type = object({
    horizontal_pod_autoscaler_controller_config = optional(object({
      horizontal_pod_autoscaler_sync_period = optional(string)
    }))
  })
  default = null
}

variable "cluster_kube_scheduler_config" {
  description = "Configuration of the Kubernetes scheduler. Valid values for `scoring_strategy.type` are `LeastAllocated` and `MostAllocated`; a resource `weight` must be between 1 and 100"
  type = object({
    node_resources_fit = optional(object({
      scoring_strategy = optional(object({
        type = optional(string)
        resources = optional(list(object({
          name   = string
          weight = optional(number)
        })))
      }))
    }))
  })
  default = null
}

# VPC infos
variable "vpc_id" {
  description = "Id of VPC"
  type        = string
}

variable "vpc_private_subnet_ids" {
  description = "List of VPC subnets ids"
  type        = list(string)
}

variable "vpc_pods_subnet_ids" {
  description = "List of VPC pods subnet ids, one per availability zone, in the order of the region's zones. Pods only use them when vpc_cni_custom_networking is true"
  type        = list(string)
}

variable "vpc_cni_custom_networking" {
  description = "Whether pods take their IPs from vpc_pods_subnet_ids (VPC CNI custom networking) instead of the node subnets. Switching it on an existing cluster only applies to nodes created afterwards"
  type        = bool
  default     = false
}

# Cluster autoscaler
variable "cluster_autoscaler_image" {
  description = "Image name of the cluster autoscaler"
  type        = string
}

variable "cluster_autoscaler_tag" {
  description = "Tag of the cluster autoscaler image"
  type        = string
}

variable "cluster_autoscaler_expander" {
  description = "Type of node group expander to be used in scale up."
  type        = string
  default     = "random"
  validation {
    condition     = contains(["random", "most-pods", "least-waste", "price", "priority"], var.cluster_autoscaler_expander)
    error_message = "Valid values for \"expander\" of the cluster-autoscaler: \"random\" | \"most-pods\" | \"least-waste\" | \"price\" | \"priority\"."
  }
}

variable "cluster_autoscaler_scale_down_enabled" {
  description = "Should CA scale down the cluster"
  type        = bool
  default     = true
}

variable "cluster_autoscaler_min_replica_count" {
  description = "Minimum number or replicas that a replica set or replication controller should have to allow their pods deletion in scale down"
  type        = number
  default     = 0
}

variable "cluster_autoscaler_scale_down_utilization_threshold" {
  description = "Node utilization level, defined as sum of requested resources divided by capacity, below which a node can be considered for scale down"
  type        = number
  default     = 0.5
}

variable "cluster_autoscaler_scale_down_non_empty_candidates_count" {
  description = "Maximum number of non empty nodes considered in one iteration as candidates for scale down with drain"
  type        = number
  default     = 30
}

variable "cluster_autoscaler_max_node_provision_time" {
  description = "Maximum time CA waits for node to be provisioned"
  type        = string
  default     = "15m"
}

variable "cluster_autoscaler_scan_interval" {
  description = "How often cluster is reevaluated for scale up or down"
  type        = string
  default     = "10s"
}

variable "cluster_autoscaler_scale_down_delay_after_add" {
  description = "How long after scale up that scale down evaluation resumes"
  type        = string
  default     = "10m"
}

variable "cluster_autoscaler_scale_down_delay_after_delete" {
  description = "How long after node deletion that scale down evaluation resumes, defaults to scan-interval"
  type        = string
}

variable "cluster_autoscaler_scale_down_delay_after_failure" {
  description = "How long after scale down failure that scale down evaluation resumes"
  type        = string
  default     = "3m"
}

variable "cluster_autoscaler_scale_down_unneeded_time" {
  description = "How long a node should be unneeded before it is eligible for scale down"
  type        = string
  default     = "10m"
}

variable "cluster_autoscaler_skip_nodes_with_system_pods" {
  description = "If true cluster autoscaler will never delete nodes with pods from kube-system (except for DaemonSet or mirror pods)"
  type        = bool
  default     = true
}

variable "cluster_autoscaler_version" {
  description = "Cluster autoscaler helm chart version"
  type        = string
}

variable "cluster_autoscaler_repository" {
  description = "Path to cluster autoscaler helm chart repository"
  type        = string
}

variable "cluster_autoscaler_namespace" {
  description = "Cluster autoscaler namespace"
  type        = string
}

# Instance refresh

variable "instance_refresh_image" {
  description = "Instance refresh image name"
  type        = string
}

variable "instance_refresh_tag" {
  description = "Instance refresh tag"
  type        = string
}

variable "instance_refresh_version" {
  description = "Instance refresh helm chart version"
  type        = string
}

variable "instance_refresh_repository" {
  description = "Path to instance refresh helm chart repository"
  type        = string
}

variable "instance_refresh_namespace" {
  description = "Instance refresh namespace"
  type        = string
}
# List of EKS managed node groups
variable "eks_managed_node_groups" {
  description = "List of EKS managed node groups"
  type        = any
  default     = null
}

variable "efs_csi" {
  description = "EFS CSI driver, deployed as the aws-efs-csi-driver EKS add-on. A null addon_version tracks the latest version compatible with the cluster; name is the IAM role name"
  type = object({
    addon_version = optional(string)
    name          = optional(string)
    controller_resources = optional(object({
      limits   = optional(map(string))
      requests = optional(map(string))
    }))
  })
  default = {}
}

variable "ebs_csi" {
  description = "EBS CSI driver, deployed as the aws-ebs-csi-driver EKS add-on. A null addon_version tracks the latest version compatible with the cluster; name is the IAM role name"
  type = object({
    addon_version = optional(string)
    name          = optional(string)
    controller_resources = optional(object({
      limits   = optional(map(string))
      requests = optional(map(string))
    }))
  })
  default = {}
}

# Encryption keys
variable "cluster_log_kms_key_id" {
  description = "KMS id to encrypt/decrypt the cluster's logs"
  type        = string
}

variable "cluster_encryption_config" {
  description = "ARN of the KMS key encrypting the cluster's secrets; empty to let the EKS module create one. EKS cannot change the key of an existing cluster, so it can only be set at cluster creation"
  type        = string
}

variable "ebs_kms_key_id" {
  description = "KMS key (id, alias or ARN) the EBS CSI driver is allowed to encrypt volumes with; empty for none. A StorageClass must still name it in its kmsKeyId parameter"
  type        = string
}

# List of self managed node groups
variable "self_managed_node_groups" {
  description = "List of self managed node groups"
  type        = any
  default     = null
}

# List of fargate profiles
variable "fargate_profiles" {
  description = "List of fargate profiles"
  type        = any
  default     = null
}
