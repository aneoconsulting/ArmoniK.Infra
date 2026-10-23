variable "name" {
  description = "Name of the reserved IP range."
  type        = string
  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$", var.name))
    error_message = "The name of the global address must match the regular expression ^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$."
  }
}

variable "address" {
  description = "The first address of the reserved range. Omit it to let GCP choose a free range of `prefix_length`."
  type        = string
  default     = null
}

variable "description" {
  description = "An optional description of the reserved range."
  type        = string
  default     = null
}

variable "ip_version" {
  description = "The IP version that will be used by this address."
  type        = string
  default     = "IPV4"
  validation {
    condition     = contains(["IPV4", "IPV6"], var.ip_version)
    error_message = "Valid values for `ip_version` are : IPV4 or IPV6."
  }
}

variable "prefix_length" {
  description = "The prefix length of the reserved range."
  type        = number
  default     = 24
  nullable    = false
}

variable "network" {
  description = "The URL of the network in which to reserve the IP range."
  type        = string
}

variable "deletion_policy" {
  description = "What a destroy does with the connection. DELETE fails while a service producer still uses it; REMOVE_PEERING then removes the VPC peering so that the network can be deleted (ephemeral environments only); ABANDON drops it from the state but leaves the peering, which still blocks the network deletion; PREVENT forbids the destroy."
  type        = string
  default     = "DELETE"
  validation {
    condition     = contains(["DELETE", "REMOVE_PEERING", "ABANDON", "PREVENT"], var.deletion_policy)
    error_message = "Valid values for `deletion_policy` are : DELETE | REMOVE_PEERING | ABANDON | PREVENT."
  }
}
