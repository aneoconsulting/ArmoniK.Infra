data "google_client_openid_userinfo" "current" {}

# Bucket names are unique across all of GCP
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  labels = {
    env    = "test"
    app    = "complete"
    module = "gcs"
    # Label values only allow lowercase letters, digits, "_" and "-"
    created_by = replace(lower(split("@", data.google_client_openid_userinfo.current.email)[0]), "/[^a-z0-9_-]/", "_")
  }
}

module "log_bucket" {
  source        = "../../../gcs"
  name          = "complete-gcs-logs-${random_string.suffix.result}"
  location      = "EU"
  force_destroy = true
  # GCS writes the usage logs as this group
  roles = {
    "roles/storage.objectCreator" = ["group:cloud-storage-analytics@google.com"]
  }
  labels = local.labels
}

module "complete_bucket" {
  source         = "../../../gcs"
  name           = "complete-gcs-${random_string.suffix.result}"
  location       = "EU"
  data_locations = ["EUROPE-WEST1", "EUROPE-WEST9"]
  storage_class  = "STANDARD"
  force_destroy  = true
  versioning     = true
  lifecycle_rule = {
    "to-nearline" = {
      action    = { type = "SetStorageClass", storage_class = "NEARLINE" }
      condition = { age = 30, matches_prefix = ["archive/"] }
    }
    "drop-old-versions" = {
      action    = { type = "Delete" }
      condition = { days_since_noncurrent_time = 7, with_state = "ARCHIVED" }
    }
  }
  # Objects deleted here are not worth recovering: no soft delete, nothing billed after deletion
  soft_delete_retention_days = 0
  logging = {
    log_bucket        = module.log_bucket.name
    log_object_prefix = "complete-gcs"
  }
  default_kms_key_name = null
  roles = {
    "roles/storage.objectUser" = ["user:${data.google_client_openid_userinfo.current.email}"]
  }
  labels = local.labels
}
