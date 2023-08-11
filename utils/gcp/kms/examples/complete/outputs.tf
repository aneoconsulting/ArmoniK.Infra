output "crypto_key" {
  description = "The generated crytpo key."
  value       = module.complete_kms_example.crypto_key
}

output "kms_key_ring" {
  description = "The generated key ring."
  value       = module.complete_kms_example.kms_key_ring
}

output "kms_ring_roles" {
  description = "The associated roles on the key ring."
  value       = module.complete_kms_example.kms_ring_roles
}

output "kms_crypto_roles" {
  description = "The associated roles on the crytpo key."
  value       = module.complete_kms_example.kms_crypto_roles
}

output "kms_key_ring_import_job" {
  description = "The import generated import job."
  value       = module.complete_kms_example.kms_key_ring_import_job
}
