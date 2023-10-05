# Profile
variable "profile" {
  description = "Profile of AWS credentials to deploy Terraform sources"
  type        = string
}

# Namespace helm chart
variable "chart_namespace" {
  type        = string
  description = "Version for chart"
  default     = "default" # Enter your desired namespace of helm chart here
}

# Version helm chart
variable "chart_version" {
  type        = string
  description = "Version for chart"
  default     = "0.1.0" # Enter your desired version of helm chart here
}

# Name helm chart
variable "chart_name" {
  type        = string
  description = "Name for chart"
  default     = "eniconfig" # Enter your desired name of Helm chart here
}

# Path helm chart
variable "chart_repository" {
  type        = string
  description = "Path to the charts repository"
  default     = "../../../charts" # Enter your desired relative path here
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
  description = "List of VPC pods subnet ids"
  type        = list(string)
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

# Encryption keys
variable "cluster_log_kms_key_id" {
  description = "KMS id to encrypt/decrypt the cluster's logs"
  type        = string
}

variable "cluster_encryption_config" {
  description = "Configuration block with encryption configuration for the cluster. To disable secret encryption, set this value to {}"
  type        = string
}

variable "ebs_kms_key_id" {
  description = "KMS key id to encrypt/decrypt EBS"
  type        = string
}

# Map roles
variable "map_roles_groups" {
  description = "List of map roles group"
  type        = list(string)
}

# Map users
variable "map_users_groups" {
  description = "List of map users group"
  type        = list(string)
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
