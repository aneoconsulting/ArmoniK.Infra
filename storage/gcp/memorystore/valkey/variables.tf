variable "name" {
  description = "ID of the instance: 4 to 63 lowercase letters, digits or hyphens, starting with a letter."
  type        = string
  validation {
    condition     = can(regex("^[a-z][-a-z0-9]{2,61}[a-z0-9]$", var.name))
    error_message = "\"name\" must be 4 to 63 lowercase letters, digits or hyphens, start with a letter and not end with a hyphen."
  }
}

variable "region" {
  description = "Region of the instance. Defaults to the provider region."
  type        = string
  default     = null
}

variable "network" {
  description = "ID of the VPC network (projects/<project>/global/networks/<name>) where the endpoints are created. It needs a service connection policy of class gcp-memorystore in the instance region."
  type        = string
}

variable "node_type" {
  description = "Machine type of the nodes, such as SHARED_CORE_NANO, STANDARD_SMALL or HIGHMEM_MEDIUM. Defaults to the server choice."
  type        = string
  default     = null
}

variable "replica_count" {
  description = "Number of replicas of the primary node, read through the reader endpoint and promoted on failure. Defaults to 0."
  type        = number
  default     = null
}

variable "engine_version" {
  description = "Valkey version, such as VALKEY_8_0. Defaults to the server choice."
  type        = string
  default     = null
}

variable "engine_configs" {
  description = "Valkey configuration parameters, such as maxmemory-policy. See [supported configurations](https://cloud.google.com/memorystore/docs/valkey/supported-instance-configurations)."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "authorization_mode" {
  description = "AUTH_DISABLED, IAM_AUTH or TOKEN_AUTH, which cannot be disabled once set. Memorystore does not accept a chosen password: IAM_AUTH tokens expire after one hour, which the Redis adapter of Core cannot refresh, and the google provider cannot read the TOKEN_AUTH tokens yet."
  type        = string
  default     = "AUTH_DISABLED"
  validation {
    condition     = contains(["AUTH_DISABLED", "IAM_AUTH", "TOKEN_AUTH"], var.authorization_mode)
    error_message = "Valid values for \"authorization_mode\" are: \"AUTH_DISABLED\" | \"IAM_AUTH\" | \"TOKEN_AUTH\"."
  }
}

variable "transit_encryption_mode" {
  description = "TLS between the clients and the instance, which cannot be changed after creation: SERVER_AUTHENTICATION or TRANSIT_ENCRYPTION_DISABLED."
  type        = string
  default     = "SERVER_AUTHENTICATION"
  validation {
    condition     = contains(["SERVER_AUTHENTICATION", "TRANSIT_ENCRYPTION_DISABLED"], var.transit_encryption_mode)
    error_message = "Valid values for \"transit_encryption_mode\" are: \"SERVER_AUTHENTICATION\" | \"TRANSIT_ENCRYPTION_DISABLED\"."
  }
}

variable "zone_distribution" {
  description = "MULTI_ZONE (the server default) spreads the nodes over the zones of the region; SINGLE_ZONE puts them in the given zone."
  type = object({
    mode = string
    zone = optional(string)
  })
  default = null
  validation {
    condition     = var.zone_distribution == null || try(contains(["MULTI_ZONE", "SINGLE_ZONE"], var.zone_distribution.mode), false)
    error_message = "Valid values for \"zone_distribution.mode\" are: \"MULTI_ZONE\" | \"SINGLE_ZONE\"."
  }
  validation {
    condition     = try(var.zone_distribution.mode, null) != "SINGLE_ZONE" || try(var.zone_distribution.zone, null) != null
    error_message = "\"zone_distribution.zone\" is required with the SINGLE_ZONE mode."
  }
}

variable "persistence" {
  description = "Persistence of the data: DISABLED, RDB snapshots or AOF log. Defaults to the server choice (disabled)."
  type = object({
    mode                    = string
    rdb_snapshot_period     = optional(string)
    rdb_snapshot_start_time = optional(string)
    aof_append_fsync        = optional(string)
  })
  default = null
  validation {
    condition     = var.persistence == null || try(contains(["DISABLED", "RDB", "AOF"], var.persistence.mode), false)
    error_message = "Valid values for \"persistence.mode\" are: \"DISABLED\" | \"RDB\" | \"AOF\"."
  }
}

variable "maintenance_window" {
  description = "Weekly one-hour maintenance window, in UTC. Defaults to a window chosen by the server."
  type = object({
    day     = string
    hours   = number
    minutes = optional(number, 0)
  })
  default = null
}

variable "kms_key" {
  description = "Cloud KMS key, in the instance region, that encrypts the data at rest. It cannot be set after creation. An object, so that the key can be created in the same apply: its ID is unknown at plan time, the object is not."
  type = object({
    id = string
  })
  default = null
}

variable "deletion_protection" {
  description = "Refuse the deletion of the instance, by any client."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels of the instance."
  type        = map(string)
  default     = {}
  nullable    = false
}
