data "google_client_config" "current" {}

# A check block warns on every plan without failing it
check "deprecated_default_kms_key_name" {
  assert {
    condition     = var.default_kms_key_name == null
    error_message = "The default_kms_key_name input of the storage/gcp/gcs module is deprecated and will be removed. Use kms_key instead."
  }
}

locals {
  # kms_key is known at plan time even when the key is created in the same apply, default_kms_key_name is not
  kms_enabled = var.kms_key != null || var.default_kms_key_name != null
  kms_key_id  = var.kms_key != null ? var.kms_key.id : var.default_kms_key_name
}

# GCS service agent, which encrypts the objects with the KMS key
data "google_storage_project_service_account" "gcs" {
  count = local.kms_enabled ? 1 : 0
}

resource "google_kms_crypto_key_iam_member" "kms" {
  count         = local.kms_enabled ? 1 : 0
  crypto_key_id = local.kms_key_id
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs[0].email_address}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

resource "google_storage_bucket" "gcs" {
  name                        = var.name
  location                    = var.location
  force_destroy               = var.force_destroy
  project                     = data.google_client_config.current.project
  storage_class               = var.storage_class
  default_event_based_hold    = var.default_event_based_hold
  labels                      = merge(var.labels, { module = "gcs" })
  requester_pays              = var.requester_pays
  uniform_bucket_level_access = var.uniform_bucket_level_access
  public_access_prevention    = var.public_access_prevention
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
  dynamic "website" {
    for_each = var.website != null ? [var.website] : []
    content {
      main_page_suffix = can(coalesce(website.value["main_page_suffix"])) ? website.value["main_page_suffix"] : null
      not_found_page   = can(coalesce(website.value["not_found_page"])) ? website.value["not_found_page"] : null
    }
  }
  dynamic "cors" {
    for_each = var.cors != null ? [var.cors] : []
    content {
      origin          = can(coalesce(cors.value["origin"])) ? cors.value["origin"] : null
      method          = can(coalesce(cors.value["method"])) ? cors.value["method"] : null
      response_header = can(coalesce(cors.value["response_header"])) ? cors.value["response_header"] : null
      max_age_seconds = can(coalesce(cors.value["max_age_seconds"])) ? cors.value["max_age_seconds"] : null
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
    for_each = local.kms_enabled ? [local.kms_key_id] : []
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
  lifecycle {
    precondition {
      condition     = var.autoclass != true || !anytrue([for rule in values(var.lifecycle_rule) : rule.action.type == "SetStorageClass"])
      error_message = "\"autoclass\" cannot be combined with a \"SetStorageClass\" lifecycle rule."
    }
    precondition {
      condition     = var.retention_policy == null || var.versioning != true
      error_message = "\"retention_policy\" cannot be combined with \"versioning\"."
    }
    precondition {
      condition     = var.kms_key == null || var.default_kms_key_name == null
      error_message = "Set \"kms_key\" or the deprecated \"default_kms_key_name\", not both."
    }
  }
  depends_on = [google_kms_crypto_key_iam_member.kms]
}

resource "google_storage_bucket_access_control" "access_control" {
  count  = can(coalesce(var.entity_bucket_access_control)) && can(coalesce(var.role_bucket_access_control)) && !coalesce(var.uniform_bucket_level_access, true) ? 1 : 0
  bucket = google_storage_bucket.gcs.name
  entity = var.entity_bucket_access_control
  role   = var.role_bucket_access_control
}

resource "google_storage_bucket_acl" "default_acl" {
  count       = can(coalesce(var.default_acl)) && !can(coalesce(var.predefined_acl)) && !can(coalesce(var.role_entity_acl)) && !coalesce(var.uniform_bucket_level_access, true) ? 1 : 0
  bucket      = google_storage_bucket.gcs.name
  default_acl = var.default_acl
}

resource "google_storage_bucket_acl" "predefined_acl" {
  count          = can(coalesce(var.predefined_acl)) && !can(coalesce(var.role_entity_acl)) && !coalesce(var.uniform_bucket_level_access, true) ? 1 : 0
  bucket         = google_storage_bucket.gcs.name
  default_acl    = var.default_acl
  predefined_acl = var.predefined_acl
}

resource "google_storage_bucket_acl" "role_entity_acl" {
  count       = !can(coalesce(var.predefined_acl)) && can(coalesce(var.role_entity_acl)) && !coalesce(var.uniform_bucket_level_access, true) ? 1 : 0
  bucket      = google_storage_bucket.gcs.name
  default_acl = var.default_acl
  role_entity = var.role_entity_acl
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
