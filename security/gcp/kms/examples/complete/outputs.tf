output "key_ring_name" {
  description = "The resource name for the KeyRing."
  value       = module.complete_kms.key_ring_name
}

output "key_ring_location" {
  description = "The location for the KeyRing."
  value       = module.complete_kms.key_ring_location
}

output "key_ring_id" {
  description = "The ID of the KeyRing."
  value       = module.complete_kms.key_ring_id
}

output "crypto_key_ids" {
  description = "The IDs of the created crypto keys, keyed by name."
  value       = module.complete_kms.crypto_key_ids
}
