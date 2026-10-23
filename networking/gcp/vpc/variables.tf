variable "name" {
  description = "Name of the VPC"
  type        = string
}

variable "auto_create_subnetworks" {
  description = "Creation of a subnet for each region automatically"
  type        = bool
  default     = false
}

variable "routing_mode" {
  description = "The network-wide routing mode to use"
  type        = string
  default     = "GLOBAL"
  validation {
    condition     = contains(["GLOBAL", "REGIONAL"], var.routing_mode)
    error_message = "Valid values for \"routing_mode\" are: \"GLOBAL\" | \"REGIONAL\"."
  }
}

variable "mtu" {
  description = "Maximum Transmission Unit in bytes"
  type        = number
  default     = 1460
  validation {
    condition     = 1300 <= var.mtu && var.mtu <= 8896
    error_message = "The minimum value for \"mtu\" field is 1300 and the maximum value is 8896 bytes (jumbo frames)."
  }
}

variable "enable_ula_internal_ipv6" {
  description = "Enable ULA internal ipv6 on this network"
  type        = bool
  default     = null
}

variable "internal_ipv6_range" {
  description = "Specify the /48 range they want from the google defined ULA prefix fd20::/20. Requires `enable_ula_internal_ipv6`"
  type        = string
  default     = null
  validation {
    condition     = var.internal_ipv6_range == null || var.enable_ula_internal_ipv6 == true
    error_message = "\"internal_ipv6_range\" requires \"enable_ula_internal_ipv6\" to be true."
  }
}

variable "network_firewall_policy_enforcement_order" {
  description = "Set the order that Firewall Rules and Firewall Policies are evaluated"
  type        = string
  default     = "AFTER_CLASSIC_FIREWALL"
  validation {
    condition = contains([
      "BEFORE_CLASSIC_FIREWALL", "AFTER_CLASSIC_FIREWALL"
    ], var.network_firewall_policy_enforcement_order)
    error_message = "Valid values for \"network_firewall_policy_enforcement_order\" are: \"BEFORE_CLASSIC_FIREWALL\" | \"AFTER_CLASSIC_FIREWALL\"."
  }
}

variable "delete_default_routes_on_create" {
  description = "Default routes (0.0.0.0/0) will be deleted immediately after network creation"
  type        = bool
  default     = null
}

variable "subnets" {
  description = "A map of subnets inside the VPC. Each subnet object has a CIDR block, a region, and a boolean set to true if its outbound internet traffic goes through Cloud NAT"
  type = map(object({
    cidr_block = string
    region     = string
    enable_nat = optional(bool, false)
  }))
  default = {}
}

variable "gke_subnet" {
  description = "The GKE subnet. The subnet contains a name, a CIDR block for nodes, a CIDR block for Pods, a CIDR block for services, a region, and a boolean set to true if its outbound internet traffic goes through Cloud NAT, which private nodes need to pull public images"
  type = object({
    name                = string
    nodes_cidr_block    = string
    pods_cidr_block     = string
    services_cidr_block = string
    region              = string
    enable_nat          = optional(bool, true)
  })
  default = null
  validation {
    condition     = var.gke_subnet == null || !contains(keys(var.subnets), try(var.gke_subnet.name, ""))
    error_message = "The name of \"gke_subnet\" must differ from the names of \"subnets\"."
  }
}

variable "enable_google_access" {
  description = "Access Google APIs and services by using Private Google Access"
  type        = bool
  default     = true
}

variable "flow_log_max_aggregation_interval" {
  description = "The maximum interval of time during which a flow of packets is captured and aggregated into a flow log"
  type        = string
  default     = "INTERVAL_5_SEC"
  validation {
    condition     = contains(["INTERVAL_5_SEC", "INTERVAL_30_SEC", "INTERVAL_1_MIN", "INTERVAL_5_MIN", "INTERVAL_10_MIN", "INTERVAL_15_MIN"], var.flow_log_max_aggregation_interval)
    error_message = "The valid values for the maximum interval of time during which a flow of packets is captured and aggregated into a flow log: \"INTERVAL_5_SEC\" | \"INTERVAL_30_SEC\" | \"INTERVAL_1_MIN\" | \"INTERVAL_5_MIN\" | \"INTERVAL_10_MIN\" | \"INTERVAL_15_MIN\"."
  }
}
