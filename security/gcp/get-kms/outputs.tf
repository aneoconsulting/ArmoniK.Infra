output "my_crypto_key_output" {
  description = "The crypto key on the GCP project."
  value       = data.google_kms_crypto_key.my_crypto_key
}
