
data "google_client_config" "current" {}

###### SECTION - IAM POLICY KMS

resource "google_kms_crypto_key_iam_member" "crypto_key_role" {
  for_each      = var.crypto_key_roles != null ? merge([for role, members in var.crypto_key_roles : { for member in members : "${role}-${member}" => { role = role, member = member } }]...) : {}
  crypto_key_id = google_kms_crypto_key.kms_crypto_key.id
  role          = each.value.role
  member        = each.value.member
}

###### SECTION - IAM POLICY KMS RING

resource "google_kms_key_ring_iam_member" "key_ring_role" {
  for_each    = var.key_ring_roles != null ? merge([for role, members in var.key_ring_roles : { for member in members : "${role}-${member}" => { role = role, member = member } }]...) : {}
  key_ring_id = google_kms_key_ring.key_ring.id
  role        = each.value.role
  member      = each.value.member
}

###### SECTION - KMS KEY RING

resource "google_kms_key_ring" "key_ring" {
  name     = var.kms_key_ring_name
  location = var.location != null ? var.location : data.google_client_config.current.region
  project  = data.google_client_config.current.project
}

###### SECTION - KMS CRYPTO KEY

resource "google_kms_crypto_key" "kms_crypto_key" {
  name                          = var.kms_crypto_key_name
  key_ring                      = google_kms_key_ring.key_ring.id
  rotation_period               = "${var.kms_crypto_key_rotation_period}s"
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

###### SECTION - KMS RING IMPORT JOB

resource "google_kms_key_ring_import_job" "import_job" {
  count            = var.google_kms_key_ring_import_job_id != null ? 1 : 0
  key_ring         = google_kms_key_ring.key_ring.id
  import_job_id    = var.google_kms_key_ring_import_job_id
  import_method    = var.google_kms_key_ring_import_job_method
  protection_level = var.google_kms_key_ring_import_job_protection_level
}
