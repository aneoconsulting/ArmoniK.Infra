
locals {
  location            = var.zone != null ? var.region : "${var.region}-${var.zone}"
  kms_crypto_key_ring = "/projects/${var.project}/locations/${local.location}/keyRings/${var.kms_crypto_key_ring}" 
}


###### SECTION - IAM POLICY KMS

resource "google_kms_crypto_key_iam_policy" "crypto_key_iam_policy" {
  depends_on = [google_kms_crypto_key.kms_crypto_key]

  crypto_key_id = google_kms_crypto_key.kms_crypto_key.id
  policy_data   = 
}

###### SECTION - IAM POLICY KMS RING

resource "google_kms_key_ring_iam_policy" "key_ring_iam_policy" {
  depends_on = [google_kms_key_ring.key_ring]

  key_ring_id = google_kms_key_ring.key_ring.id
  policy_data = 
}


###### SECTION - KMS KEY RING

resource "google_kms_key_ring" "key_ring" {
  name     = var.google_kms_key_ring_name
  location = local.location
  project  = var.project_id
  id       = 
}

###### SECTION - KMS CRYPTO KEY

resource "google_kms_crypto_key" "kms_crypto_key" {
  depends_on = [google_kms_key_ring.key_ring]

  name                          = var.kms_crypto_key_name
  key_ring                      = google_kms_key_ring.key_ring.id
  rotation_period               = var.kms_crypto_key_rotation_period
  labels                        = var.kms_crypto_key_labels
  purpose                       = var.kms_crypto_key_purpose
  version_template              = var.kms_crypto_key_version_template
  destroy_scheduled_duration    = var.kms_crypto_key_destroy_scheduled_duration
  import_only                   = var.kms_crypto_key_import_only
  skip_initial_version_creation = var.kms_crypto_key_skip_initial_version_creation

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
  attestation      = var.kms_crypto_key_version_attestation
}


###### SECTION - KMS RING IMPORT JOB

resource "google_kms_key_ring_import_job" "kms_key_ring_import_job" {
  key_ring         = google_kms_key_ring.keyring.id
  import_job_id    = "my-import-job"
  import_method    = "RSA_OAEP_3072_SHA1_AES_256"
  protection_level = "SOFTWARE"

  id               = ""
  name             = ""
  expire_time      = ""
  state            = ""
  public_key       = ""
  attestation      = ""
}

###### SECTION - KMS CIPHERTEXT

resource "google_kms_secret_ciphertext" "ciphertext_password" {
  crypto_key                    = google_kms_crypto_key.cryptokey.id
  plaintext                     = "my-secret-password"
  additional_authenticated_data = ""
}

