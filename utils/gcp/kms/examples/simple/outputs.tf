output "crypto-key" {
    value = module.simple_kms_example.crypto-key
}

output "kms_key_ring" {
    value = module.simple_kms_example.kms_key_ring
}

output "kms_ring_iam_policy" {
    value = module.simple_kms_example.kms_ring_iam_policy
}

output "kms_crypto_key_iam_policy" {
    value = module.simple_kms_example.kms_crypto_key_iam_policy
}

output "kms_ciphertext" {
    value = module.simple_kms_example.kms_ciphertext
}

output "kms_key_ring_import_job" {
    value = module.simple_kms_example.kms_key_ring_import_job
}
