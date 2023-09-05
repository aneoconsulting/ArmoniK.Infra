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

variable "name" {
  description = "Name of the resource."
  type        = string
  validation {
    condition     = can(regex("[a-z]([-a-z0-9]*[a-z0-9])?.", var.name))
    error_message = "The name of the global adress must match the following regular expression : [a-z]([-a-z0-9]*[a-z0-9])?."
  }
}

variable "description" {
  description = "An optional description for the global_address resource"
  type        = string
  default     = null
}

variable "ip" {
  description = "The static IP represented by this resources."
  type        = string
  default     = null
}

variable "prefix_length" {
  description = "The prefix length if the resource represents an IP range."
  type        = number
  default     = null
}

variable "ip_version" {
  description = "The IP version that will be used by this address."
  type        = string
  default     = "IPV4"
  validation {
    condition     = can(regex("IPV4|IPV6", var.ip_version))
    error_message = "The value can only be IPV4 or IPV6"
  }
}

variable "adress_type" {
  description = "The type of address to reserve."
  type        = string
  validation {
    condition     = can(regex("INTERNAL|EXTERNAL", var.adress_type))
    error_message = "The value can only be INTERNAL or EXTERNAL"
  }
  default = "INTERNAL"
}
