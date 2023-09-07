output "my_crypto_key_output" {
  description = "The crypto keys on the GCP project from the specified KeyRing."
  value       = module.simple_kms.my_crypto_key_output
}

output "key_ring_name" {
  description = "The resource name for the KeyRing."
  value       = module.simple_kms.key_ring_name
}

output "key_ring_location" {
  description = "The location for the KeyRing."
  value       = module.simple_kms.key_ring_location
}

output "key_ring_id" {
  description = "The ID of the KeyRing."
  value       = module.simple_kms.key_ring_id
}