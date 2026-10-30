variable "key_ring_name" {
  description = "The resource name for the KeyRing."
  type        = string
}

variable "key_ring_roles" {
  description = "Roles to bind on the KeyRing, as a map of role to members."
  type        = map(set(string))
  default     = {}
  nullable    = false
}

variable "crypto_keys" {
  description = "Map of crypto keys to create in the KeyRing, keyed by name. The fields follow the [google_kms_crypto_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) arguments; `description` is set as a label of the key; `roles` binds roles on the key, as a map of role to members."
  type = map(object({
    description                   = optional(string)
    purpose                       = optional(string, "ENCRYPT_DECRYPT")
    rotation_period               = optional(string)
    destroy_scheduled_duration    = optional(string)
    import_only                   = optional(bool, false)
    skip_initial_version_creation = optional(bool, false)
    version_template = optional(object({
      algorithm        = string
      protection_level = optional(string)
    }))
    roles = optional(map(set(string)), {})
  }))
  default  = {}
  nullable = false
}

variable "location" {
  description = "The location for the KeyRing, the provider region by default. A full list of valid locations can be found by running \"gcloud kms locations list\"."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels with user-defined metadata to apply to crypto keys."
  type        = map(string)
  default     = {}
  nullable    = false
}
