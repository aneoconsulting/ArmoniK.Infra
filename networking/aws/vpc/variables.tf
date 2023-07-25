variable "name" {
  description = "Name of the VPC"
  type        = string
  default     = ""
}

variable "cidr" {
  description = "Main CIDR bloc for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool"
  type        = set(string)
  default     = []
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = set(string)
  default     = []
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = set(string)
  default     = []
}

variable "flow_log_cloudwatch_log_group_kms_key_id" {
  description = "ARN of the KMS to encrypt/decrypt VPC flow logs"
  type        = string
  default     = null
}

variable "flow_log_cloudwatch_log_group_retention_in_days" {
  description = "Number of days for retention of VPC flow logs in the CloudWatch"
  type        = number
  default     = null
}

variable "flow_log_file_format" {
  description = "The format for the flow log"
  type        = string
  default     = "plain-text"
  validation {
    condition     = contains(["plain-text", "parquet"], var.flow_log_file_format)
    error_message = "The valid values for the VPC flow log format for the flow log: \"plain-text\" | \"parque\"."
  }
}

variable "flow_log_max_aggregation_interval" {
  description = "The maximum interval of time during which a flow of packets is captured and aggregated into a flow log"
  type        = number
  default     = 60
  validation {
    condition     = contains([60, 600], var.flow_log_max_aggregation_interval)
    error_message = "The valid values for tThe maximum interval of time during which a flow of packets is captured and aggregated into a flow log: 60 | 600."
  }
}

variable "tags" {
  description = "Map of keys,values to tags VPC resources"
  type        = map(string)
  default     = {}
}

variable "eks_name" {
  description = "Name of the EKS to be deployed in this VPC"
  type        = string
  default     = null
}

variable "pod_subnets" {
  description = "List of CIDR blocks fot Pods"
  type        = set(string)
  default     = []
}

variable "use_karpenter" {
  description = "Use Karpenter for the cluster autoscaling"
  type        = bool
  default     = false
}
