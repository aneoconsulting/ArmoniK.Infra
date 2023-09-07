variable "crypto_key_names" {
  description = "The names of the crypto keys to retrieve from the GCP project."
  type        = list(string)
}

variable "key_ring_name" {
  description = "The key ring name on which the crypto key belongs to."
  type        = string
}
