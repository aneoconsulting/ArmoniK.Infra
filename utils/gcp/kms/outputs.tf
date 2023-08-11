output "crypto_key" {
  description = "The generated crytpo key."
  value       = google_kms_crypto_key.kms_crypto_key
}

output "kms_key_ring" {
  description = "The generated key ring."
  value       = google_kms_key_ring.key_ring
}

output "kms_ring_roles" {
  description = "The associated roles on the key ring."
  value       = google_kms_key_ring_iam_member.key_ring_role
}

output "kms_crypto_roles" {
  description = "The associated roles on the crytpo key."
  value       = google_kms_crypto_key_iam_member.crypto_key_role
}

output "kms_key_ring_import_job" {
  description = "The import generated import job."
  value       = google_kms_key_ring_import_job.import_job
}
