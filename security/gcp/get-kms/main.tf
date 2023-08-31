data "google_kms_key_ring" "my_key_ring" {
  name     = var.key_ring_name
  location = data.google_client_config.current.region
}

data "google_kms_crypto_key" "my_crypto_key" {
  name     = var.crypto_key_name
  key_ring = data.google_kms_key_ring.my_key_ring.id
}

data "google_client_config" "current" {}
