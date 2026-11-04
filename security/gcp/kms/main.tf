data "google_client_config" "current" {}

locals {
  key_ring_roles = merge([
    for role, members in var.key_ring_roles : {
      for member in members : "${role}-${member}" => { role = role, member = member }
    }
  ]...)
  crypto_key_roles = merge([
    for key, value in var.crypto_keys : merge([
      for role, members in value.roles : {
        for member in members : "${key}-${role}-${member}" => { key = key, role = role, member = member }
      }
    ]...)
  ]...)
}

resource "google_kms_key_ring" "key_ring" {
  name     = var.key_ring_name
  location = coalesce(var.location, data.google_client_config.current.region)
  project  = data.google_client_config.current.project
}

resource "google_kms_key_ring_iam_member" "key_ring_role" {
  for_each    = local.key_ring_roles
  key_ring_id = google_kms_key_ring.key_ring.id
  role        = each.value.role
  member      = each.value.member
}

resource "google_kms_crypto_key" "keys" {
  for_each                      = var.crypto_keys
  key_ring                      = google_kms_key_ring.key_ring.id
  name                          = each.key
  labels                        = can(coalesce(each.value.description)) ? merge(var.labels, { description = each.value.description }) : var.labels
  purpose                       = each.value.purpose
  rotation_period               = each.value.rotation_period
  destroy_scheduled_duration    = each.value.destroy_scheduled_duration
  import_only                   = each.value.import_only
  skip_initial_version_creation = each.value.skip_initial_version_creation
  dynamic "version_template" {
    for_each = each.value.version_template != null ? [each.value.version_template] : []
    content {
      algorithm        = version_template.value.algorithm
      protection_level = version_template.value.protection_level
    }
  }
}

resource "google_kms_crypto_key_iam_member" "crypto_key_roles" {
  for_each      = local.crypto_key_roles
  crypto_key_id = google_kms_crypto_key.keys[each.value.key].id
  role          = each.value.role
  member        = each.value.member
}
