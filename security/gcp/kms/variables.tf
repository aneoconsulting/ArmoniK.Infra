variable "key_ring_name" {
  description = "The resource name for the KeyRing."
  type        = string
}

variable "key_ring_roles" {
  description = "Roles to bind to the kKeyRing."
  type        = map(set(string))
  default     = null
}

variable "crypto_keys" {
  description = "Map of crypto keys representing a logical key that can be used for cryptographic operations. The valid parameters are defined in [Crypto key in Terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key). In addition, a map of roles, of type \"map(set(string))\", can be defined for each crypto key, ex: \"roles = {\"roles/cloudkms.cryptoKeyEncrypter\" = [\"user:jane@example.com\", \"user:david@example.com\"]}\"."
  type        = any
  default     = null
}

variable "location" {
  description = "The location for the KeyRing. A full list of valid locations can be found by running \"gcloud kms locations list\"."
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels with user-defined metadata to apply to crypto keys."
  type        = map(string)
  default     = null
}
