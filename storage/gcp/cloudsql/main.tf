data "google_client_config" "current" {}

locals {
  project = data.google_client_config.current.project
  region  = coalesce(var.region, data.google_client_config.current.region)
  labels  = merge(var.labels, { module = "cloudsql" })

  # The self link of a network is accepted too: the API wants projects/<project>/global/networks/<name>
  network = regex("projects/[^/]+/global/networks/[^/]+$", var.network)

  database_flags = merge({
    # Core streams the changes of its tables through logical replication (publication armonik_pub)
    "cloudsql.logical_decoding" = "on"
    # Up to 100 connections per Core process; the default derived from the memory of the tier runs out with a few
    # dozen pods
    max_connections = "500"
  }, var.database_flags)
}

resource "google_sql_database_instance" "postgresql" {
  name                = var.name
  project             = local.project
  region              = local.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    edition                     = var.edition
    tier                        = var.tier
    availability_type           = var.availability_type
    disk_size                   = var.disk.size
    disk_autoresize             = var.disk.autoresize
    disk_type                   = var.disk.type
    deletion_protection_enabled = var.deletion_protection
    user_labels                 = local.labels
    # The provision script of the REPLICATION attribute goes through the ExecuteSql API
    data_api_access = "ALLOW_DATA_API"

    dynamic "database_flags" {
      for_each = local.database_flags
      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }

    # No public IP, no VPC peering: one Private Service Connect endpoint in the client network, created by Cloud SQL
    # with its DNS record. The server certificate, issued by a Google-managed CA, carries that DNS name, so clients
    # can verify both the CA and the host (verify-full).
    ip_configuration {
      ipv4_enabled   = false
      ssl_mode       = "ENCRYPTED_ONLY"
      server_ca_mode = "GOOGLE_MANAGED_CAS_CA"

      psc_config {
        psc_enabled                        = true
        allowed_consumer_projects          = [local.project]
        psc_auto_connection_policy_enabled = true
        psc_auto_dns_enabled               = true
        psc_auto_connections {
          consumer_network            = local.network
          consumer_service_project_id = local.project
        }
      }
    }

    backup_configuration {
      enabled                        = var.backup.enabled
      start_time                     = var.backup.start_time
      point_in_time_recovery_enabled = var.backup.point_in_time_recovery
      transaction_log_retention_days = var.backup.point_in_time_recovery ? var.backup.transaction_log_retention_days : null
      backup_retention_settings {
        retained_backups = var.backup.retained_backups
      }
    }

    dynamic "maintenance_window" {
      for_each = var.maintenance_window == null ? [] : [var.maintenance_window]
      content {
        day  = maintenance_window.value.day
        hour = maintenance_window.value.hour
      }
    }
  }
}

resource "google_sql_database" "armonik" {
  name     = var.database
  project  = local.project
  instance = google_sql_database_instance.postgresql.name
  # Dropping it fails while Core is connected; it goes away with the instance anyway
  deletion_policy = "ABANDON"
}

resource "random_password" "user" {
  length  = 32
  special = false
}

resource "google_sql_user" "armonik" {
  name     = var.user
  project  = local.project
  instance = google_sql_database_instance.postgresql.name
  type     = "BUILT_IN"
  password = random_password.user.result
  # A PostgreSQL role owning objects cannot be dropped; it goes away with the instance anyway
  deletion_policy = "ABANDON"
}

# The REPLICATION attribute, which the logical replication slot of Core needs, is only granted in SQL, by the postgres
# user. The provision script runs it through the Cloud SQL API (ExecuteSql), so with no network path to the instance,
# as postgres, whose password it reads from a regional secret in the region of the instance.
resource "random_password" "postgres" {
  length  = 32
  special = false
}

resource "google_secret_manager_regional_secret" "postgres" {
  secret_id = "${var.name}-postgres"
  project   = local.project
  location  = local.region
  labels    = local.labels
}

resource "google_secret_manager_regional_secret_version" "postgres" {
  secret      = google_secret_manager_regional_secret.postgres.id
  secret_data = random_password.postgres.result
}

resource "google_sql_user" "postgres" {
  name     = "postgres"
  project  = local.project
  instance = google_sql_database_instance.postgresql.name
  type     = "BUILT_IN"
  password = random_password.postgres.result
  # The default user of the instance: Terraform only sets its password
  deletion_policy = "ABANDON"
}

resource "google_sql_provision_script" "replication" {
  instance                = google_sql_database_instance.postgresql.name
  project                 = local.project
  database                = google_sql_database.armonik.name
  user                    = google_sql_user.postgres.name
  password_secret_version = google_secret_manager_regional_secret_version.postgres.name
  description             = "REPLICATION attribute of ${google_sql_user.armonik.name}"
  # Idempotent, run again only when the user changes
  script = "ALTER USER \"${google_sql_user.armonik.name}\" WITH REPLICATION;"
}
