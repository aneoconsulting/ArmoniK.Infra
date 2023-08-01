variable "zone" {
  description = ""
  type        = string
  default     = null
}

variable "region" {
  description = ""
  type        = string
}

variable "project_id" {
  description = ""
  type        = string
}

variable "project_id" {
  description = ""
  type        = string
}

# SECTION - KMS CRYPTO KEY

variable "kms_crypto_key_name" {
  description = 
  type        = string
}

variable "kms_crypto_key_ring" {
  description = 
  type        = string
}

variable "kms_crypto_key_labels" {
  description = 
  type        = map(string)
  default     = null 
}

variable "kms_crypto_key_purpose" {
  description = 
  type        = string
  default     = "ENCRYPT_DECRYPT" 
}

variable "kms_crypto_key_rotation_period" {
  description = 
  type        = string
  default     = null 
}

variable "kms_crypto_key_version_template" {
  description = 
  type        = object({
    algorithm = string
    protection_level = optional(string)
  })
  default     = null 
}


variable "kms_crypto_key_destroy_scheduled_duration" {
  description = ""
  type        = string
  default     = "24h"
}


variable "kms_crypto_key_import_only" {
  description = ""
  type        = bool
  default     = false
}

variable "kms_crypto_key_skip_initial_version_creation" {
  description = ""
  type        = bool 
  default     = false
}

###### SECTION - KMS KEY RING

variable "kms_key_ring_name" {
  description = ""
  type        = string
}

variable "kms_key_ring_id" {
  description = ""
  type        = string
}

###### SECTION - KMS CRYPTO KEY VERSION


variable "kms_crypto_key_version_cyrpto_key" {
  description = ""
  type        = string
}

variable "kms_crypto_key_version_state" {
  description = ""
  type        = string
  default     = null 
}

variable "kms_crypto_key_version_id" {
  description = ""
  type        = string
}

variable "kms_crypto_key_version_name" {
  description = ""
  type        = string
  default     = null 
}

variable "kms_crypto_key_version_protection_level" {
  description = ""
  type        = string
  default     = null 
}

variable "kms_crypto_key_version_generate_time" {
  description = ""
  type        = string
  default     = null 
}

variable "kms_crypto_key_version_algorithm" {
  description = ""
  type        = string
  default     = null 
}

variable "kms_crypto_key_version_attestation" {
  description = ""
  type        = object({
    format  = optional(string)
    content = optional(string)
    cert_chains                       = object({
      cavium_certs           = optional(string)
      google_card_certs      = optional(string)
      google_partition_certs = optional(string)
    })
    external_protection_level_options = object({
      external_key_uri        = optional(string)
      ekm_connection_key_path = optional(string)
    })
  })
  default     = null 
}





  crypto_key       = google_kms_crypto_key.kms_crypto_key.id
  state            =
  name             =
  id               = 
  protection_level =
  generate_time    =
  algorithm        =
  attestation      =