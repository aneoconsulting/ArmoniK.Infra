
data "google_client_config" "current" {}

###### SECTION - IAM POLICY KMS

resource "google_kms_crypto_key_iam_policy" "crypto_key_iam_policy" {
  count = var.google_kms_crypto_key_iam_policy_data != null ? 1 : 0

  crypto_key_id = google_kms_crypto_key.kms_crypto_key.id
  policy_data   = var.google_kms_crypto_key_iam_policy_data
}

###### SECTION - IAM POLICY KMS RING

resource "google_kms_key_ring_iam_policy" "key_ring_iam_policy" {
  depends_on = [google_kms_key_ring.key_ring]
  count      = var.google_kms_key_ring_iam_policy_data != null ? 1 : 0

  key_ring_id = google_kms_key_ring.key_ring.id
  policy_data = var.google_kms_key_ring_iam_policy_data
}


###### SECTION - KMS KEY RING

resource "google_kms_key_ring" "key_ring" {
  name     = var.kms_key_ring_name
  location = data.google_client_config.current.region
  project  = data.google_client_config.current.project
}

###### SECTION - KMS CRYPTO KEY

resource "google_kms_crypto_key" "kms_crypto_key" {
  name                          = var.kms_crypto_key_name
  key_ring                      = google_kms_key_ring.key_ring.id
  rotation_period               = var.kms_crypto_key_rotation_period
  labels                        = var.kms_crypto_key_labels
  purpose                       = var.kms_crypto_key_purpose
  import_only                   = var.kms_crypto_key_import_only
  skip_initial_version_creation = var.kms_crypto_key_skip_initial_version_creation


  dynamic "version_template" {
    for_each = var.kms_crypto_key_version_template != null ? [var.kms_crypto_key_version_template] : []
    content {
      algorithm        = var.kms_crypto_key_version_template.value["algorithm"]
      protection_level = var.kms_crypto_key_version_template.value["protection_level"]
    }
  }

  lifecycle {
    prevent_destroy = true
  }

}

###### SECTION - KMS CRYPTO KEY VERSION

resource "google_kms_crypto_key_version" "kms_crypto_key_version" {
  depends_on = [google_kms_crypto_key.kms_crypto_key]

  crypto_key = google_kms_crypto_key.kms_crypto_key.id
  state      = var.kms_crypto_key_version_state
}

###### SECTION - KMS RING IMPORT JOB

resource "google_kms_key_ring_import_job" "kms_key_ring_import_job" {
  count            = var.google_kms_key_ring_import_job_id != null ? 1 : 0
  key_ring         = google_kms_key_ring.key_ring.id
  import_job_id    = var.google_kms_key_ring_import_job_id
  import_method    = var.google_kms_key_ring_import_job_method
  protection_level = var.google_kms_key_ring_import_job_protection_level
}

###### SECTION - KMS CIPHERTEXT

resource "google_kms_secret_ciphertext" "ciphertext_password" {
  count                         = var.google_kms_secret_ciphertext_plaintext != null ? 1 : 0
  crypto_key                    = google_kms_crypto_key.kms_crypto_key.id
  plaintext                     = var.google_kms_secret_ciphertext_plaintext
  additional_authenticated_data = var.google_kms_secret_ciphertext_additional_authenticated_data
}
