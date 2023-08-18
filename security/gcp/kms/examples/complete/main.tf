data "google_client_openid_userinfo" "current" {}

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

locals {
  date   = <<-EOT
#!/bin/bash
set -e
DATE=$(date +%F-%H-%M-%S)
jq -n --arg date "$DATE" '{"date":$date}'
  EOT
  labels = {
    env             = "test"
    app             = "complete"
    module          = "kms"
    "create_by"     = split("@", data.google_client_openid_userinfo.current.email)[0]
    "creation_date" = null_resource.timestamp.triggers["date"]
  }
  key_ring_roles = {
    "roles/cloudkms.admin" = ["user:hbitoun@aneo.fr", "user:lzianekhodja@aneo.fr"],
    "roles/editor"         = ["user:hbitoun@aneo.fr"]
  }
  crypto_keys = {
    "key-1" = {
      purpose                       = "ENCRYPT_DECRYPT"
      rotation_period               = "86400s"
      import_only                   = false
      skip_initial_version_creation = true
      version_template              = {
        algorithm = "CRYPTO_KEY_VERSION_ALGORITHM_UNSPECIFIED"
      }
    }
    "key-4" = {
      purpose          = "ASYMMETRIC_SIGN"
      version_template = {
        algorithm        = "EC_SIGN_P384_SHA384"
        protection_level = "SOFTWARE"
      }
    }
    "key-3" = {
      purpose                    = "ENCRYPT_DECRYPT"
      destroy_scheduled_duration = "86400s"
      crypto_key_roles           = {
        "roles/cloudkms.cryptoKeyEncrypter" = ["user:hbitoun@aneo.fr"],
        "roles/cloudkms.admin"              = ["user:hbitoun@aneo.fr", "user:lzianekhodja@aneo.fr"]
      }
    }
  }
}

module "complete_kms" {
  source         = "../../../kms"
  key_ring_name  = "complete-kms"
  key_ring_roles = local.key_ring_roles
  crypto_keys    = local.crypto_keys
  location       = "europe"
  labels         = local.labels
}
