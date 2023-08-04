# SECTION - KMS CRYPTO KEY

variable "kms_crypto_key_name" {
  description = "The resource name for the CryptoKey."
  type        = string
}

variable "kms_crypto_key_labels" {
  description = "Labels with user-defined metadata to apply to this resource."
  type        = map(string)
  default     = null
}

variable "kms_crypto_key_purpose" {
  description = "The immutable purpose of this CryptoKey."
  type        = string
  default     = "ENCRYPT_DECRYPT"
}

variable "kms_crypto_key_rotation_period" {
  description = "Every time this period passes, generate a new CryptoKeyVersion and set it as the primary. The first rotation will take place after the specified period."
  type        = number
  default     = null
  validation {
    condition     = var.kms_crypto_key_rotation_period > 86400
    error_message = "The rotation period has the format of a decimal number with up to 9 fractional digits. It must be greater than a day (86400)"
  }
}

variable "kms_crypto_key_version_template" {
  description = "A template describing settings for new crypto key versions."
  type = object({
    algorithm        = string
    protection_level = optional(string)
  })
  default = null
}

variable "kms_crypto_key_import_only" {
  description = "Whether this key may contain imported versions only."
  type        = bool
  default     = false
}

variable "kms_crypto_key_skip_initial_version_creation" {
  description = "If set to true, the request will create a CryptoKey without any CryptoKeyVersions."
  type        = bool
  default     = false
}

###### SECTION - KMS KEY RING

variable "kms_key_ring_name" {
  description = "The resource name for the KeyRing."
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
  description = "The policy data for the kms ring"
  type        = string
  default     = null
}

###### SECTION - IAM POLICY KMS

variable "google_kms_crypto_key_iam_policy_data" {
  description = "The policy data for the crypto key"
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
