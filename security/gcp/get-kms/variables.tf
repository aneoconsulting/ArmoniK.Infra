variable "crypto_key_name" {
  description = "The name of the crypto key to retrieve from the GCP project."
  type        = string
}

variable "key_ring_name" {
  description = "The key ring name on which the crypto key belongs to."
  type        = string
}
