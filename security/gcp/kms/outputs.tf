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

output "key_ring_roles" {
  description = "The IAM roles for the KeyRing."
  value       = google_kms_key_ring_iam_member.key_ring_role
}

output "crypto_key_ids" {
  description = "The Map of the created crypto keys."
  value       = { for key, value in google_kms_crypto_key.keys : key => value.id }
}

output "crypto_key_roles" {
  description = "The IAM roles for the crypto keys."
  value       = google_kms_crypto_key_iam_member.crypto_key_roles
}
