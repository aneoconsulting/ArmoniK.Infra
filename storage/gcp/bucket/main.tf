data "google_client_config" "current" {}

resource "google_storage_bucket" "bucket" {
  name                        = var.bucket_name
  location                    = var.location != null ? var.location : data.google_client_config.current.region
  storage_class               = var.storage_class
  uniform_bucket_level_access = var.uniform_bucket_level_access
  public_access_prevention    = var.public_access_prevention
  force_destroy               = var.force_destroy
  default_event_based_hold    = var.default_event_based_hold
  labels                      = var.labels
  requester_pays              = var.requester_pays

  dynamic "website" {
    for_each = var.website != null ? [var.website] : []
    content {
      main_page_suffix = website.value["main_page_suffix"]
      not_found_page   = website.value["not_found_page"]
    }
  }

  dynamic "versioning" {
    for_each = var.versioning != null ? [var.versioning] : []
    content {
      enabled = versioning.value["enabled"]
    }
  }
  
  dynamic "autoclass" {
    for_each = var.autoclass != null ? [var.autoclass] : []
    content {
      enabled = autoclass.value["enabled"]
    }
  }
  
  dynamic "cors" {
    for_each = var.cors != null ? [var.cors] : []
    content {
      origin          = cors.value["origin"]
      method          = cors.value["method"]
      response_header = cors.value["response_header"]
      max_age_seconds = cors.value["max_age_seconds"]
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rule != null ? [var.lifecycle_rule] : []
    content {
      action {
        type          = lifecycle_rule.value["action"]["type"]
        storage_class = lifecycle_rule.value["action"]["storage_class"]
      }
      condition {
        age                        = lifecycle_rule.value["condition"]["age"]
        created_before             = lifecycle_rule.value["condition"]["created_before"]
        with_state                 = lifecycle_rule.value["condition"]["with_state"]
        matches_storage_class      = lifecycle_rule.value["condition"]["matches_storage_class"]
        matches_prefix             = lifecycle_rule.value["condition"]["matches_prefix"]
        matches_suffix             = lifecycle_rule.value["condition"]["matches_suffix"]
        num_newer_versions         = lifecycle_rule.value["condition"]["num_newer_versions"]
        custom_time_before         = lifecycle_rule.value["condition"]["custom_time_before"]
        days_since_custom_time     = lifecycle_rule.value["condition"]["days_since_custom_time"]
        days_since_noncurrent_time = lifecycle_rule.value["condition"]["days_since_noncurrent_time"]
        noncurrent_time_before     = lifecycle_rule.value["condition"]["noncurrent_time_before"]
      }
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_policy != null ? [var.retention_policy] : []
    content {
      is_locked        = retention_policy.value["is_locked"]
      retention_period = retention_policy.value["retention_period"]
    }
  }

  dynamic "logging" {
    for_each = var.logging != null ? [var.logging] : []
    content {
      log_bucket        = logging.value["log_bucket"]
      log_object_prefix = logging.value["log_object_prefix"]
    }
  }

  dynamic "encryption" {
    for_each = var.encryption != null ? [var.encryption] : []
    content {
      default_kms_key_name = encryption.value["default_kms_key_name"]
    }
  }

  dynamic "custom_placement_config" {
    for_each = var.custom_placement_config != null ? [var.custom_placement_config] : []
    content {
      data_locations = custom_placement_config.value["data_locations"]
    }
  }
}

############### SECTION - Bucket acl

resource "google_storage_bucket_acl" "acl" {
  bucket      = google_storage_bucket.bucket.name
  role_entity = var.role_entity
}

############### SECTION - Bucket policy

resource "google_storage_bucket_iam_member" "role" {
  for_each    = var.roles != null ?  merge([ for role, members in var.roles: { for member in members: "${role}-${member}" => {role = role, member = member }}]...) : {}
  bucket      = google_storage_bucket.bucket.name
  role        = each.value.role
  member      = each.value.member
}