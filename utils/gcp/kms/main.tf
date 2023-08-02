
data "google_client_config" "current" {}

locals {
  kms_crypto_key_ring = "/projects/${data.google_client_config.current.project}/locations/${data.google_client_config.current.region}/keyRings/${var.kms_crypto_key_ring}"
}


###### SECTION - IAM POLICY KMS

resource "google_kms_crypto_key_iam_policy" "crypto_key_iam_policy" {
  depends_on = [google_kms_crypto_key.kms_crypto_key]
  for_each   = var.google_kms_crypto_key_iam_policy_data != null ? var.google_kms_crypto_key_iam_policy_data : {}

  crypto_key_id = google_kms_crypto_key.kms_crypto_key.id
  policy_data   = var.google_kms_crypto_key_iam_policy_data
}

###### SECTION - IAM POLICY KMS RING

resource "google_kms_key_ring_iam_policy" "key_ring_iam_policy" {
  depends_on = [google_kms_key_ring.key_ring]
  for_each   = var.google_kms_key_ring_iam_policy_data != null ? var.google_kms_key_ring_iam_policy_data : {}

  key_ring_id = google_kms_key_ring.key_ring.id
  policy_data = var.google_kms_key_ring_iam_policy_data
}


###### SECTION - KMS KEY RING

resource "google_kms_key_ring" "key_ring" {
  name     = var.google_kms_key_ring_name
  location = data.google_client_config.current.region
  project  = data.google_client_config.current.project
}

###### SECTION - KMS CRYPTO KEY

resource "google_kms_crypto_key" "kms_crypto_key" {
  depends_on = [google_kms_key_ring.key_ring]

  name                          = var.kms_crypto_key_name
  key_ring                      = google_kms_key_ring.key_ring.id
  rotation_period               = var.kms_crypto_key_rotation_period
  labels                        = var.kms_crypto_key_labels
  purpose                       = var.kms_crypto_key_purpose
  destroy_scheduled_duration    = var.kms_crypto_key_destroy_scheduled_duration
  import_only                   = var.kms_crypto_key_import_only
  skip_initial_version_creation = var.kms_crypto_key_skip_initial_version_creation


  dynamic "version_template" {
    for_each = var.kms_crypto_key_version_template != null ? [var.kms_crypto_key_version_template] : []
    content {
      algorithm        = var.kms_crypto_key_version_template.value["algorithm"]
      protection_level = var.kms_crypto_key_version_template.value["protection_level"]
    }
  }

}

###### SECTION - KMS CRYPTO KEY VERSION

resource "google_kms_crypto_key_version" "kms_crypto_key_version" {
  depends_on = [google_kms_crypto_key.kms_crypto_key]

  crypto_key       = google_kms_crypto_key.kms_crypto_key.id
  state            = var.kms_crypto_key_version_state
  name             = var.kms_crypto_key_version_name
  id               = var.kms_crypto_key_version_id
  protection_level = var.kms_crypto_key_version_protection_level
  generate_time    = var.kms_crypto_key_version_generate_time
  algorithm        = var.kms_crypto_key_version_algorithm

  dynamic "attestion" {
    for_each = var.kms_crypto_key_version_attestation != null ? [var.kms_crypto_key_version_attestation] : []
    content {
      format  = var.kms_crypto_key_version_attestation.value["format"]
      content = var.kms_crypto_key_version_attestation.value["content"]
      cert_chains {
        cavium_certs           = var.kms_crypto_key_version_attestation.value["cert_chains"]["cavium_certs"]
        google_card_certs      = var.kms_crypto_key_version_attestation.value["cert_chains"]["google_card_certs"]
        google_partition_certs = var.kms_crypto_key_version_attestation.value["cert_chains"]["google_partition_certs"]
      }
      external_protection_level_options {
        external_key_uri        = var.kms_crypto_key_version_attestation.value["external_protection_level_options"]["external_key_uri"]
        ekm_connection_key_path = var.kms_crypto_key_version_attestation.value["external_protection_level_options"]["ekm_connection_key_path"]
      }
    }
  }
}


###### SECTION - KMS RING IMPORT JOB

resource "google_kms_key_ring_import_job" "kms_key_ring_import_job" {
  count            = var.google_kms_key_ring_import_job_ID ? 1 : 0
  key_ring         = google_kms_key_ring.keyring.id
  import_job_id    = var.google_kms_key_ring_import_job_ID
  import_method    = var.google_kms_key_ring_import_job_method
  protection_level = var.google_kms_key_ring_import_job_protection_level

  id          = var.google_kms_key_ring_import_job_id
  name        = var.google_kms_key_ring_import_job_name
  expire_time = var.google_kms_key_ring_import_job_expire_time
  state       = var.google_kms_key_ring_import_job_state

  dynamic "public_key" {
    for_each = var.google_kms_key_ring_import_job_public_key != null ? [var.google_kms_key_ring_import_job_public_key] : []
    content {
      pem = var.google_kms_key_ring_import_job_public_key.value["pem"]
    }
  }


  dynamic "attestation" {
    for_each = var.google_kms_key_ring_import_job_attestation != null ? [var.google_kms_key_ring_import_job_attestation] : []
    content {
      format  = var.google_kms_key_ring_import_job_attestation.value["format"]
      content = var.google_kms_key_ring_import_job_attestation.value["content"]
    }
  }

}

###### SECTION - KMS CIPHERTEXT

resource "google_kms_secret_ciphertext" "ciphertext_password" {
  count                         = var.google_kms_secret_ciphertext_plaintext != null ? 1 : 0
  crypto_key                    = google_kms_crypto_key.cryptokey.id
  plaintext                     = var.google_kms_secret_ciphertext_plaintext
  additional_authenticated_data = var.google_kms_secret_ciphertext_additional_authenticated_data
}

