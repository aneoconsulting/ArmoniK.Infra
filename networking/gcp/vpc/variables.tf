variable "project" {
  description = "Project name"
  type        = string
}

variable "region" {
  description = "Region where to deploy the different subnets"
  type        = string
}

variable "name" {
  description = "Name of the VPC"
  type        = string
  default     = "armonik-vpc"
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "pod_subnets" {
  description = "List of CIDR blocks for Pods"
  type        = list(string)
  default     = []
}

variable "enable_external_access" {
  description = "Boolean to disable external access"
  type        = bool
  default     = true
}

variable "enable_google_access" {
  description = "Enable the access to Google APIs to VMs without public IP"
  type    = bool
  default = true
}

variable "flow_log_max_aggregation_interval" {
  description = "The maximum interval of time during which a flow of packets is captured and aggregated into a flow log"
  type        = string
  default     = "INTERVAL_1_MIN"
  validation {
    condition     = contains(["INTERVAL_5_SEC", "INTERVAL_30_SEC", "INTERVAL_1_MIN", "INTERVAL_5_MIN", "INTERVAL_10_MIN", "INTERVAL_15_MIN"], var.flow_log_max_aggregation_interval)
    error_message = "The valid values for the maximum interval of time during which a flow of packets is captured and aggregated into a flow log: INTERVAL_5_SEC | INTERVAL_30_SEC | INTERVAL_1_MIN | INTERVAL_5_MIN | INTERVAL_10_MIN | INTERVAL_15_MIN."
  }
}

variable "gke_name" {
  description = "Name of the GKE to be deployed in this VPC"
  type        = string
  default     = null
}