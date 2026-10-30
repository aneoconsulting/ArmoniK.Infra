terraform {
  required_version = ">= 1.0"
  required_providers {
    # REMOVE_PEERING in deletion_policy needs 8.1
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}
