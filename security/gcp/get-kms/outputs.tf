output "my_crypto_key_output" {
  description = "The crypto keys on the GCP project from the specified KeyRing."
  value       = { for key, value in data.google_kms_crypto_key.my_crypto_keys : key => value.id }
}

output "key_ring_name" {
  description = "The resource name for the KeyRing."
  value       = data.google_kms_key_ring.my_key_ring.name
}

output "key_ring_location" {
  description = "The location for the KeyRing."
  value       = data.google_kms_key_ring.my_key_ring.location
}

output "key_ring_id" {
  description = "The ID of the KeyRing."
  value       = data.google_kms_key_ring.my_key_ring.id
}
