output "crypto-key" {
  value = google_kms_crypto_key.kms_crypto_key
}

output "kms_key_ring" {
  value = google_kms_key_ring.key_ring
}

output "kms_ring_iam_policy" {
  value = google_kms_key_ring_iam_policy.key_ring_iam_policy
}

output "kms_crypto_key_iam_policy" {
  value = google_kms_crypto_key_iam_policy.crypto_key_iam_policy
}

output "kms_ciphertext" {
  value = google_kms_secret_ciphertext.ciphertext_password
}

output "kms_key_ring_import_job" {
  value = google_kms_key_ring_import_job.kms_key_ring_import_job
}


