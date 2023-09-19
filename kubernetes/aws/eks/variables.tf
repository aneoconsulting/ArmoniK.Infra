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
  description = ""
  type = string
}

variable "cluster_endpoint_private_access" {
  description = ""
  type = bool
}

variable "cluster_endpoint_private_access_cidrs" {
  description = ""
  type = list(string)
}

variable "cluster_endpoint_private_access_sg" {
  description = ""
  type = list(string)
}

variable "cluster_endpoint_public_access" {
  description = ""
  type = bool
}

variable "cluster_endpoint_public_access_cidrs" {
  description = ""
  type = list(string)
}

variable "cluster_log_retention_in_days" {
  description = ""
  type = number
}

# VPC infos
variable "vpc_id" {
  description = ""
  type = string
}

variable "vpc_private_subnet_ids" {
  description = ""
  type = list(string)
}

variable "vpc_pods_subnet_ids" {
  description = ""
  type = list(string)
}

# Cluster autoscaler
variable "cluster_autoscaler_image" {
  description = ""
  type = string
}

variable "cluster_autoscaler_tag" {
  description = ""
  type = string
}

variable "cluster_autoscaler_expander" {
  description = ""
  type = string
  validation {
    condition     = contains(["random", "most-pods", "least-waste", "price", "priority"], var.cluster_autoscaler_expander)
    error_message = "Valid values for \"expander\" of the cluster-autoscaler: \"random\" | \"most-pods\" | \"least-waste\" | \"price\" | \"priority\"."
  }
}

variable "cluster_autoscaler_scale_down_enabled" {
  description = ""
  type = bool
}

variable "cluster_autoscaler_min_replica_count" {
  description = ""
  type = number
}

variable "cluster_autoscaler_scale_down_utilization_threshold" {
  description = ""
  type = number
}

variable "cluster_autoscaler_scale_down_non_empty_candidates_count" {
  description = ""
  type = number
}

variable "cluster_autoscaler_max_node_provision_time" {
  description = ""
  type = string
}

variable "cluster_autoscaler_scan_interval" {
  description = ""
  type = string
}

variable "cluster_autoscaler_scale_down_delay_after_add" {
  description = ""
  type = string
}

variable "cluster_autoscaler_scale_down_delay_after_delete" {
  description = ""
  type = string
}

variable "cluster_autoscaler_scale_down_delay_after_failure" {
  description = ""
  type = string
}

variable "cluster_autoscaler_scale_down_unneeded_time" {
  description = ""
  type = string
}

variable "cluster_autoscaler_skip_nodes_with_system_pods" {
  description = ""
  type = bool
}

variable "cluster_autoscaler_version" {
  description = ""
  type = string
}

variable "cluster_autoscaler_repository" {
  description = ""
  type = string
}

variable "cluster_autoscaler_namespace" {
  description = ""
  type = string
}

# Instance refresh

variable "instance_refresh_image" {
  description = ""
  type = string
}

variable "instance_refresh_tag" {
  description = ""
  type = string
}

variable "instance_refresh_version" {
  description = ""
  type = string
}

variable "instance_refresh_repository" {
  description = ""
  type = string
}

variable "instance_refresh_namespace" {
  description = ""
  type = string
}
# List of EKS managed node groups
variable "eks_managed_node_groups" {
  description = "List of EKS managed node groups"
  type        = any
  default     = null
}

# Encryption keys
variable "cluster_log_kms_key_id" {
  description = ""
  type = string
}

variable "cluster_encryption_config" {
  description = ""
  type = string
}

variable "ebs_kms_key_id" {
  description = ""
  type = string
}

# Map roles
variable "map_roles_rolearn" {
  description = ""
  type = string
}

variable "map_roles_username" {
  description = ""
  type = string
}

variable "map_roles_groups" {
  description = ""
  type = list(string)
}

# Map users
variable "map_users_userarn" {
  description = ""
  type = string
}

variable "map_users_username" {
  description = ""
  type = string
}

variable "map_users_groups" {
  description = ""
  type = list(string)
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
