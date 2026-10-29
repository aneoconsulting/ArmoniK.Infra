data "google_client_config" "current" {}

# GCS service agent, which encrypts the objects with the KMS key
data "google_storage_project_service_account" "gcs" {
  count = var.kms_key != null ? 1 : 0
}

resource "google_kms_crypto_key_iam_member" "kms" {
  count         = var.kms_key != null ? 1 : 0
  crypto_key_id = var.kms_key.id
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs[0].email_address}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

resource "google_storage_bucket" "gcs" {
  name          = var.name
  location      = var.location
  force_destroy = var.force_destroy
  project       = data.google_client_config.current.project
  storage_class = var.storage_class
  labels        = merge(var.labels, { module = "gcs" })
  # Access goes through IAM only (var.roles) by default, ACLs being kept only for the S3 adapter of Core
  uniform_bucket_level_access = var.uniform_bucket_level_access
  # "enforced" rejects any grant to allUsers or allAuthenticatedUsers, whatever the organization policy
  public_access_prevention = var.public_access_prevention
  dynamic "autoclass" {
    for_each = var.autoclass != null ? [var.autoclass] : []
    content {
      enabled = autoclass.value
    }
  }
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rule
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lifecycle_rule.value.action.storage_class
      }
      condition {
        age                        = lifecycle_rule.value.condition.age
        created_before             = lifecycle_rule.value.condition.created_before
        with_state                 = lifecycle_rule.value.condition.with_state
        matches_storage_class      = lifecycle_rule.value.condition.matches_storage_class
        matches_prefix             = lifecycle_rule.value.condition.matches_prefix
        matches_suffix             = lifecycle_rule.value.condition.matches_suffix
        num_newer_versions         = lifecycle_rule.value.condition.num_newer_versions
        custom_time_before         = lifecycle_rule.value.condition.custom_time_before
        days_since_custom_time     = lifecycle_rule.value.condition.days_since_custom_time
        days_since_noncurrent_time = lifecycle_rule.value.condition.days_since_noncurrent_time
        noncurrent_time_before     = lifecycle_rule.value.condition.noncurrent_time_before
      }
    }
  }
  dynamic "versioning" {
    for_each = var.versioning != null ? [var.versioning] : []
    content {
      enabled = versioning.value
    }
  }
  dynamic "retention_policy" {
    for_each = var.retention_policy != null ? [var.retention_policy] : []
    content {
      is_locked        = retention_policy.value.is_locked
      retention_period = retention_policy.value.retention_period
    }
  }
  # Without the block, the bucket keeps the server value (7 days by default)
  dynamic "soft_delete_policy" {
    for_each = var.soft_delete_retention_days != null ? [var.soft_delete_retention_days] : []
    content {
      retention_duration_seconds = soft_delete_policy.value * 86400
    }
  }
  dynamic "logging" {
    for_each = var.logging != null ? [var.logging] : []
    content {
      log_bucket        = logging.value.log_bucket
      log_object_prefix = logging.value.log_object_prefix
    }
  }
  dynamic "encryption" {
    for_each = var.kms_key != null ? [var.kms_key.id] : []
    content {
      default_kms_key_name = encryption.value
    }
  }
  dynamic "custom_placement_config" {
    for_each = var.data_locations != null ? [var.data_locations] : []
    content {
      data_locations = custom_placement_config.value
    }
  }
  depends_on = [google_kms_crypto_key_iam_member.kms]
}

resource "google_storage_bucket_iam_member" "role" {
  for_each = merge([
    for role, members in var.roles : {
      for member in members : "${role}-${member}" => { role = role, member = member }
    }
  ]...)
  bucket = google_storage_bucket.gcs.name
  role   = each.value.role
  member = each.value.member
}
