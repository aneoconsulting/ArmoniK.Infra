######## SECTION - VPC to get

variable "vpc_link" {
  description = "The vpc on which the psa will be created"
  type        = string
}

######## SECTION - PSA 

variable "service_name" {
  description = "The private service access to create"
  type        = string
  default     = "servicenetworking.googleapis.com"
}

######## SECTION - GLOBAL ADDRESS

variable "global_address_name" {
  description = "Name of the resource."
  type        = string
  validation {
    condition     = can(regex("[a-z]([-a-z0-9]*[a-z0-9])?.", var.global_address_name))
    error_message = "The name of the global adress must match the following regular expression : [a-z]([-a-z0-9]*[a-z0-9])?."
  }
}

variable "global_address_description" {
  description = "An optional description for the global_address resource"
  type        = string
  default     = null
}

variable "global_address_ip" {
  description = "The static IP represented by this resources."
  type        = string
  default     = null
}

variable "global_address_prefix_length" {
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