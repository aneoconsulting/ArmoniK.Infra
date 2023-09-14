variable "name" {
  description = "Name of the resource."
  type        = string
  validation {
    condition     = can(regex("[a-z]([-a-z0-9]*[a-z0-9])?.", var.name))
    error_message = "The name of the global address must match the following regular expression : [a-z]([-a-z0-9]*[a-z0-9])?."
  }
}

variable "address" {
  description = "The IP address or beginning of the address range represented by this resource. This can be supplied as an input to reserve a specific address or omitted to allow GCP to choose a valid one for you."
  type        = string
  default     = null
}

variable "description" {
  description = "An optional description of this resource."
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
  description = "The prefix length if the resource represents an IP range."
  type        = number
  default     = null
}

variable "address_type" {
  description = "The type of the address to reserve."
  type        = string
  default     = "INTERNAL"
  validation {
    condition     = contains(["EXTERNAL", "INTERNAL"], coalesce(var.address_type, "EXTERNAL"))
    error_message = "Valid values for `address_type` are : EXTERNAL | INTERNAL."
  }
}

variable "network" {
  description = " The URL of the network in which to reserve the IP range. ."
  type        = string
}
