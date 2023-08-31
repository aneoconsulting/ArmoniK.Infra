output "my_crypto_key_output" {
  description = "The crypto key on the GCP project."
  value       = module.simple_kms.my_crypto_key_output
}
