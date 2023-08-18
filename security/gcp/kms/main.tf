data "google_client_config" "current" {}

resource "google_kms_key_ring" "key_ring" {
  name     = var.key_ring_name
  location = coalesce(var.location, data.google_client_config.current.region)
  project  = data.google_client_config.current.project
}

resource "google_kms_key_ring_iam_member" "key_ring_role" {
  for_each = var.key_ring_roles != null ? merge([
  for role, members in var.key_ring_roles : {
  for member in members : "${role}-${member}" => {
    role   = role
    member = member
  }}]...) : {}
  key_ring_id = google_kms_key_ring.key_ring.id
  role        = each.value["role"]
  member      = each.value["member"]
}

resource "google_kms_crypto_key" "keys" {
  for_each                      = var.crypto_keys != null ? toset(keys(var.crypto_keys)) : []
  key_ring                      = google_kms_key_ring.key_ring.id
  name                          = each.key
  labels                        = can(coalesce(var.crypto_keys[each.key]["description"])) ? merge(var.labels, { description = var.crypto_keys[each.key]["description"] }) : var.labels
  purpose                       = try(var.crypto_keys[each.key]["purpose"], null)
  rotation_period               = try(var.crypto_keys[each.key]["rotation_period"], null)
  destroy_scheduled_duration    = try(var.crypto_keys[each.key]["destroy_scheduled_duration"], null)
  import_only                   = try(var.crypto_keys[each.key]["import_only"], false)
  skip_initial_version_creation = try(var.crypto_keys[each.key]["skip_initial_version_creation"], false)
  dynamic "version_template" {
    for_each = can(coalesce(var.crypto_keys[each.key]["version_template"]["algorithm"])) ? [1] : []
    content {
      algorithm        = try(var.crypto_keys[each.key]["version_template"]["algorithm"], null)
      protection_level = try(var.crypto_keys[each.key]["version_template"]["protection_level"], null)
    }
  }
}

resource "google_kms_crypto_key_iam_member" "crypto_key_roles" {
  for_each = {
  for element in flatten([
  for data in [
  for key, value in google_kms_crypto_key.keys : {
    name   = value.name,
    key_id = value.id,
    roles  = try(var.crypto_keys["roles"], [])
  }
  ] : [
  for role, members in data.roles : [
  for member in members : {
    name   = data.name,
    key_id = data.key_id,
    role   = role,
    member = member
  }
  ]
  ]
  ]) : "${element.name}-${element.role}-${element.member}" => {
    key_id = element.key_id, role = element.role, member = element.member
  }
  }
  crypto_key_id = each.value["key_id"]
  member        = each.value["member"]
  role          = each.value["role"]
}
