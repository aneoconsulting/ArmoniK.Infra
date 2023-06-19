variable "vpc_id" {
  description = "The ID of the VPC in which the endpoint will be used"
}

variable "security_group_ids" {
  description = "The IDs of security groups to associate with the network interfaces"
  default     = []
}

variable "subnet_ids" {
  description = "The IDs of subnets in which to create the network interfaces for the endpoints"
  default     = []
}

variable "endpoints" {
  description = "A map of interface and/or gateway endpoints containing their properties and configurations"
  default     = {}
}

variable "timeouts" {
  description = "Define maximum timeout for creating, updating, and deleting VPC endpoint resources"
  default     = {}
}

variable "tags" {
  description = "A map of tags to use on all resources"
  default     = {}
}
