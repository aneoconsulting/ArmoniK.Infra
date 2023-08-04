# SECTION - KMS CRYPTO KEY

variable "kms_crypto_key_name" {
  description = ""
  type        = string
}

variable "kms_crypto_key_labels" {
  description = ""
  type        = map(string)
  default     = null
}

variable "kms_crypto_key_purpose" {
  description = ""
  type        = string
  default     = "ENCRYPT_DECRYPT"
}

variable "kms_crypto_key_rotation_period" {
  description = ""
  type        = string
  default     = null
}

variable "kms_crypto_key_version_template" {
  description = ""
  type = object({
    algorithm        = string
    protection_level = optional(string)
  })
  default = null
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

###### SECTION - KMS RING IMPORT JOB

variable "google_kms_key_ring_import_job_id" {
  description = "It must be unique within a KeyRing. If not specified it will not create an import job."
  type        = string
  validation {
    condition     = can(regex("[a-zA-Z0-9_-]{1,63}", var.google_kms_key_ring_import_job_id)) || var.google_kms_key_ring_import_job_id == null
    error_message = "google_kms_key_ring_import_job_id can only match the regular expression : [a-zA-Z0-9_-]{1,63}"
  }
  default = null
}

variable "google_kms_key_ring_import_job_method" {
  description = "The wrapping method to be used for incoming key material."
  type        = string
  validation {
    condition     = can(regex("RSA_OAEP_3072_SHA1_AES_256|RSA_OAEP_4096_SHA1_AES_256", var.google_kms_key_ring_import_job_method))
    error_message = "google_kms_key_ring_import_job_method can only take one of these values : RSA_OAEP_3072_SHA1_AES_256 or RSA_OAEP_4096_SHA1_AES_256"
  }
  default = "RSA_OAEP_3072_SHA1_AES_256"
}

variable "google_kms_key_ring_import_job_protection_level" {
  description = "The protection level of the ImportJob."
  type        = string
  validation {
    condition     = can(regex("SOFTWARE|HSM|EXTERNAL", var.google_kms_key_ring_import_job_protection_level))
    error_message = "google_kms_key_ring_import_job_protection_level can only take one of these values : SOFTWARE or EXTERNAL or HSM"
  }
  default = "SOFTWARE"
}

###### SECTION - IAM POLICY KMS RING

variable "google_kms_key_ring_iam_policy_data" {
  description = ""
  type        = string
  default     = null
}

###### SECTION - IAM POLICY KMS

variable "google_kms_crypto_key_iam_policy_data" {
  description = ""
  type        = string
  default     = null
}

###### SECTION - KMS CIPHERTEXT

variable "google_kms_secret_ciphertext_plaintext" {
  description = "The plaintext to be encrypted. If not specified it will not create the KMS Ciphertext"
  type        = string
  default     = null
}

variable "google_kms_secret_ciphertext_additional_authenticated_data" {
  description = "The additional authenticated data used for integrity checks during encryption and decryption."
  type        = string
  default     = null
}
