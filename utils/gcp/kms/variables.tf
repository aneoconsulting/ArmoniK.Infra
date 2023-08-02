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

###### SECTION - KMS RING IMPORT JOB

variable "google_kms_key_ring_import_job_ID" {
  description = "It must be unique within a KeyRing."
  type        = string
  validation {
    condition     = can(regex("[a-zA-Z0-9_-]{1,63}"))
    error_message = "google_kms_key_ring_import_job_ID can only match the regular expression : [a-zA-Z0-9_-]{1,63}"
  }
}

variable "google_kms_key_ring_import_job_method" {
  description = "The wrapping method to be used for incoming key material."
  type        = string
  validation {
    condition     = can(regex("RSA_OAEP_3072_SHA1_AES_256|RSA_OAEP_4096_SHA1_AES_256"))
    error_message = "google_kms_key_ring_import_job_method can only take one of these values : RSA_OAEP_3072_SHA1_AES_256 or RSA_OAEP_4096_SHA1_AES_256"
  }
}

variable "google_kms_key_ring_import_job_protection_level" {
  description = "The protection level of the ImportJob."
  type        = string
  validation {
    condition     = can(regex("SOFTWARE|HSM|EXTERNAL"))
    error_message = "google_kms_key_ring_import_job_protection_level can only take one of these values : SOFTWARE or EXTERNAL or HSM"
  }
}

variable "google_kms_key_ring_import_job_id" {
  description = "An identifier for the resource with format {{name}}"
  type        = string
  default = null
}

variable "google_kms_key_ring_import_job_name" {
  description = "The resource name for this ImportJob"
  type        = ""
  default = null
}

variable "google_kms_key_ring_import_job_expire_time" {
  description = "The time at which this resource is scheduled for expiration and can no longer be used. This is in RFC3339 text format"
  type        = string
  default = null
}

variable "google_kms_key_ring_import_job_state" {
  description = "The current state of the ImportJob, indicating if it can be used."
  type        = string
  default = null
}

variable "google_kms_key_ring_import_job_public_key" {
  description = "The public key with which to wrap key material prior to import."
  type        = object({
    pem = string
  })
  default = null
}

variable "google_kms_key_ring_import_job_attestation" {
  description = "Statement that was generated and signed by the key creator (for example, an HSM) at key creation time."
  type        = object({
    format  = string
    content = string
  })
  default = null
}

###### SECTION - IAM POLICY KMS RING

variable "google_kms_key_ring_iam_policy_data" {
  description = ""
  type        = map(list(string))
  default     = null 
}

###### SECTION - IAM POLICY KMS

variable "google_kms_crypto_key_iam_policy_data" {
  description = ""
  type        = map(list(string))
  default     = null 
}

###### SECTION - KMS CIPHERTEXT

variable "google_kms_secret_ciphertext_plaintext" {
  description = "The plaintext to be encrypted."
  type        = string
}

variable "google_kms_secret_ciphertext_additional_authenticated_data" {
  description = "The additional authenticated data used for integrity checks during encryption and decryption."
  type        = string
  default     = null 
}