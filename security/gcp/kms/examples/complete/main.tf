data "google_client_openid_userinfo" "current" {}

# Key rings are never deleted: a random suffix lets the example be applied again after a destroy
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  current_user = "user:${data.google_client_openid_userinfo.current.email}"
  labels = {
    env    = "test"
    app    = "complete"
    module = "kms"
    # Label values only allow lowercase letters, digits, "_" and "-"
    created_by = replace(lower(split("@", data.google_client_openid_userinfo.current.email)[0]), "/[^a-z0-9_-]/", "_")
  }
  key_ring_roles = {
    "roles/cloudkms.admin"  = [local.current_user]
    "roles/cloudkms.viewer" = [local.current_user]
  }
  crypto_keys = {
    "key-1" = {
      rotation_period               = "86400s"
      skip_initial_version_creation = true
      version_template = {
        algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
      }
    }
    "key-2" = {
      purpose = "ASYMMETRIC_SIGN"
      version_template = {
        algorithm        = "EC_SIGN_P384_SHA384"
        protection_level = "SOFTWARE"
      }
    }
    "key-3" = {
      destroy_scheduled_duration = "86400s"
      roles = {
        "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [local.current_user]
      }
    }
  }
}

module "complete_kms" {
  source         = "../../../kms"
  key_ring_name  = "complete-kms-${random_string.suffix.result}"
  key_ring_roles = local.key_ring_roles
  crypto_keys    = local.crypto_keys
  location       = "europe"
  labels         = local.labels
}
