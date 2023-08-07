locals {
  kms_crypto_key_labels = {
    "complete-example-label" = "complete-label"
  }

  version_template = {
    algorithm        = "RSA_SIGN_PSS_2048_SHA256"
    protection_level = "SOFTWARE"
  }

  key_ring_roles = {
    "roles/cloudkms.admin" = ["user:jane@example.com", "user:jane2@example.com"],
    "roles/editor"         = ["user:jane@example.com"]
  }

  crypto_key_roles = {
    "roles/cloudkms.cryptoKeyEncrypter" = ["user:jane@example.com", "user:jane2@example.com"],
    "roles/cloudkms.admin"              = ["user:jane@example.com"]
  }


}

module "complete_kms_example" {
  source = "../../../kms"

  kms_crypto_key_name = "complete-key-test"
  kms_key_ring_name   = "complete-key-ring"

  kms_crypto_key_labels                        = local.kms_crypto_key_labels
  kms_crypto_key_purpose                       = "ENCRYPT_DECRYPT"
  kms_crypto_key_rotation_period               = 87000
  kms_crypto_key_version_template              = local.version_template
  kms_crypto_key_import_only                   = false
  kms_crypto_key_skip_initial_version_creation = false

  google_kms_key_ring_import_job_id               = "my-import-job-id-123456"
  google_kms_key_ring_import_job_method           = "RSA_OAEP_3072_SHA1_AES_256"
  google_kms_key_ring_import_job_protection_level = "SOFTWARE"

  key_ring_roles   = local.key_ring_roles
  crypto_key_roles = local.crypto_key_roles

  google_kms_secret_ciphertext_plaintext = "my-secret-password"
}
