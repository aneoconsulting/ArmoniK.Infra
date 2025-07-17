variable "cluster_name" {
  description = "Name of the MongoDB Atlas cluster"
  type        = string
}

variable "project_id" {
  description = "ID of the MongoDB Atlas project"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for secrets."
  type        = string
}

variable "region" {
  description = "AWS region for the private endpoint."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to create the VPC endpoint in"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the VPC endpoint"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Subnet IDs to attach to the VPC endpoint"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}
