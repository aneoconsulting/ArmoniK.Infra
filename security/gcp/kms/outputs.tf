output "key_ring_name" {
  description = "The resource name for the KeyRing."
  value       = google_kms_key_ring.key_ring.name
}

output "key_ring_location" {
  description = "The location for the KeyRing."
  value       = google_kms_key_ring.key_ring.location
}

output "key_ring_id" {
  description = "The ID of the KeyRing."
  value       = google_kms_key_ring.key_ring.id
}

output "crypto_key_ids" {
  description = "The IDs of the created crypto keys, keyed by name."
  value       = { for key, value in google_kms_crypto_key.keys : key => value.id }
}
