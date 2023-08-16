variable "vpc_network" {
  description = "The vpc_network to create."
  type        = string
}

variable "service_name" {
  description = "The private service access to create"
  type        = string
}

variable "global_adress_name" {
  description = "Name of the resource."
  type        = string
  validation {
    condition     = can(regex("[a-z]([-a-z0-9]*[a-z0-9])?.", var.global_adress_name))
    error_message = "The name of the global adress must match the following regular expression : [a-z]([-a-z0-9]*[a-z0-9])?."
  }
}

variable "global_adress_description" {
  description = "An optional description for the global_address resource"
  type        = string
  default     = null
}

variable "global_adress_adress" {
  description = "The static IP represented by this resources."
  type        = string
}

variable "global_adress_prefix_length" {
  description = "The prefix length if the resource represents an IP range."
  type        = number
  default     = 0
}

variable "global_address_ip_version" {
  description = "The IP version that will be used by this address."
  type        = string
  validation {
    condition     = can(regex("IPV4|IPV6", var.global_address_ip_version))
    error_message = "The value can only be IPV4 or IPV6"
  }
}

variable "global_address_adress_type" {
  description = "The type of address to reserve."
  type        = string
  validation {
    condition     = can(regex("INTERNAL|EXTERNAL", var.global_address_adress_type))
    error_message = "The value can only be INTERNAL or EXTERNAL"
  }
  default = "EXTERNAL"
}

variable "global_address_purpose" {
  description = "The purpose of this resource"
  type        = string
  validation {
    condition     = can(regex("GCE_ENDPOINT|DNS_RESOLVER|VPC_PEERING|NAT_AUTO|IPSEC_INTERCONNECT|SHARED_LOADBALANCER_VIP|SHARED_LOADBALANCER_VIP", var.global_address_purpose))
    error_message = "The value can only be one theses: GCE_ENDPOINT, DNS_RESOLVER, VPC_PEERING, NAT_AUTO, IPSEC_INTERCONNECT, SHARED_LOADBALANCER_VIP, SHARED_LOADBALANCER_VIP"
  }
}
