data "google_client_config" "current" {}

locals {
  project = data.google_client_config.current.project
  region  = coalesce(var.region, data.google_client_config.current.region)
  # Only the auto-created endpoints of var.network, by connection type (primary, reader)
  endpoints = {
    for connection in flatten(google_memorystore_instance.valkey.endpoints[*].connections[*].psc_auto_connection[*]) :
    connection.connection_type => connection
  }
  # Active tokens of the default user, by creation time: the latest one is the password during a rotation
  auth_tokens = {
    for token in try(jsondecode(data.http.auth_tokens[0].response_body).authTokens, []) :
    token.createTime => token.token if token.state == "ACTIVE"
  }
}

# The Memorystore service agent must exist before it can be granted the key
resource "google_project_service_identity" "kms" {
  count    = var.kms_key != null ? 1 : 0
  provider = google-beta
  project  = local.project
  service  = "memorystore.googleapis.com"
}

# The email comes back before the account exists: granting it the key right away fails on the first use of
# Memorystore in a project
resource "time_sleep" "kms" {
  count           = var.kms_key != null ? 1 : 0
  create_duration = "30s"
  triggers = {
    email = google_project_service_identity.kms[0].email
  }
}

resource "google_kms_crypto_key_iam_member" "kms" {
  count         = var.kms_key != null ? 1 : 0
  crypto_key_id = var.kms_key.id
  member        = "serviceAccount:${time_sleep.kms[0].triggers.email}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
}

resource "google_memorystore_instance" "valkey" {
  instance_id = var.name
  location    = local.region
  project     = local.project
  # The Redis adapter of Core deletes several keys without hash tags in one command, which cluster mode refuses
  # (CROSSSLOT): a single shard, without cluster mode
  mode                        = "CLUSTER_DISABLED"
  shard_count                 = 1
  node_type                   = var.node_type
  replica_count               = var.replica_count
  engine_version              = var.engine_version
  engine_configs              = var.engine_configs
  authorization_mode          = var.authorization_mode
  transit_encryption_mode     = var.transit_encryption_mode
  kms_key                     = try(var.kms_key.id, null)
  deletion_protection_enabled = var.deletion_protection
  labels                      = merge(var.labels, { module = "memorystore-valkey" })
  # Needs a service connection policy of class gcp-memorystore on the network, in the instance region
  desired_auto_created_endpoints {
    network    = var.network
    project_id = local.project
  }
  dynamic "zone_distribution_config" {
    for_each = var.zone_distribution != null ? [var.zone_distribution] : []
    content {
      mode = zone_distribution_config.value.mode
      zone = zone_distribution_config.value.zone
    }
  }
  dynamic "persistence_config" {
    for_each = var.persistence != null ? [var.persistence] : []
    content {
      mode = persistence_config.value.mode
      dynamic "rdb_config" {
        for_each = persistence_config.value.mode == "RDB" ? [persistence_config.value] : []
        content {
          rdb_snapshot_period     = rdb_config.value.rdb_snapshot_period
          rdb_snapshot_start_time = rdb_config.value.rdb_snapshot_start_time
        }
      }
      dynamic "aof_config" {
        for_each = persistence_config.value.mode == "AOF" ? [persistence_config.value] : []
        content {
          append_fsync = aof_config.value.aof_append_fsync
        }
      }
    }
  }
  dynamic "maintenance_policy" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      weekly_maintenance_window {
        day = maintenance_policy.value.day
        start_time {
          hours   = maintenance_policy.value.hours
          minutes = maintenance_policy.value.minutes
        }
      }
    }
  }
  depends_on = [google_kms_crypto_key_iam_member.kms]
}

# With TOKEN_AUTH, Memorystore creates the default user and its token along with the instance. The google provider
# cannot read the tokens yet (GoogleCloudPlatform/magic-modules PR 19541): read them from the API.
data "http" "auth_tokens" {
  count = var.authorization_mode == "TOKEN_AUTH" ? 1 : 0
  url   = "https://memorystore.googleapis.com/v1/${google_memorystore_instance.valkey.id}/tokenAuthUsers/default/authTokens"
  request_headers = {
    Authorization = "Bearer ${data.google_client_config.current.access_token}"
  }
  retry {
    attempts     = 5
    min_delay_ms = 2000
  }
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Reading the auth tokens of the default user failed with HTTP status ${self.status_code}."
    }
  }
}
