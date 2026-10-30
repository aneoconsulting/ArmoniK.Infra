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

output "key_ring_roles" {
  description = "The IAM roles for the KeyRing."
  value       = module.complete_kms.key_ring_roles
}

output "crypto_key_ids" {
  description = "The Map of the created crypto keys."
  value       = module.complete_kms.crypto_key_ids
}

output "crypto_key_roles" {
  description = "The IAM roles for the crypto keys."
  value       = module.complete_kms.crypto_key_roles
}
