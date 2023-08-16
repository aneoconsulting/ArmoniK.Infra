data "google_client_openid_userinfo" "current" {}

locals {
  cors = {
    origin          = ["http://my-origin-example.com"]
    method          = ["GET", "POST"]
    response_header = ["*"]
    max_age_seconds = 18
  }
  labels = {
    env             = "test"
    app             = "complete"
    module          = "gcs"
    "create_by"     = split("@", data.google_client_openid_userinfo.current.email)[0]
    "creation_date" = null_resource.timestamp.triggers["date"]
  }
  lifecycle_rule = {
    "rule-1" = {
      action = {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
      condition = {
        age                        = 18
        created_before             = "2025-10-02"
        custom_time_before         = "2025-10-02"
        matches_prefix             = ["test", "qual"]
        matches_storage_class      = ["STANDARD", "NEARLINE"]
        num_newer_versions         = 0
        days_since_custom_time     = null
        days_since_noncurrent_time = null
        matches_suffix             = null
        noncurrent_time_before     = null
        with_state                 = null
      }
    }
  }
  logging = {
    log_bucket        = "another-bucket"
    log_object_prefix = "log"
  }
  retention_policy = {
    is_locked        = false
    retention_period = 10
  }
  website = {
    main_page_suffix = "test"
    not_found_page   = "/error-page.fr"
  }
  role_entity_acl = ["OWNER:user-hbitoun@aneo.fr", "READER:group-gcp.armonik.devops@aneo.fr"]
  roles = {
    "roles/storage.objectCreator" = ["user:hbitoun@aneo.fr", "user:lzianekhodja@aneo.fr"],
    "roles/storage.admin"         = ["user:hbitoun@aneo.fr"]
  }
  date = <<-EOT
#!/bin/bash
set -e
DATE=$(date +%F-%H-%M-%S)
jq -n --arg date "$DATE" '{"date":$date}'
  EOT
}

resource "local_file" "date_sh" {
  filename = "${path.module}/generated/date.sh"
  content  = local.date
}

data "external" "static_timestamp" {
  program     = ["bash", "date.sh"]
  working_dir = "${path.module}/generated"
  depends_on  = [local_file.date_sh]
}

resource "null_resource" "timestamp" {
  triggers = {
    date = data.external.static_timestamp.result.date
  }
  lifecycle {
    ignore_changes = [triggers]
  }
}

module "complete_gcs_bucket" {
  source                       = "../../../gcs"
  name                         = "complete-gcs-bucket"
  location                     = "EU"
  autoclass                    = true
  cors                         = local.cors
  data_locations               = ["EUROPE-WEST9", "EUROPE-WEST1"]
  default_event_based_hold     = false
  default_kms_key_name         = null
  force_destroy                = true
  labels                       = local.labels
  lifecycle_rule               = local.lifecycle_rule
  logging                      = local.logging
  public_access_prevention     = "inherited"
  requester_pays               = false
  retention_policy             = local.retention_policy
  storage_class                = "STANDARD"
  uniform_bucket_level_access  = false
  versioning                   = true
  website                      = local.website
  entity_bucket_access_control = "allUsers"
  role_bucket_access_control   = "READER"
  default_acl                  = null
  predefined_acl               = null
  role_entity_acl              = local.role_entity_acl
  roles                        = local.roles
}
