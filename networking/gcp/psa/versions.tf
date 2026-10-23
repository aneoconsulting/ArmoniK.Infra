terraform {
  required_version = ">= 1.9"
  required_providers {
    # 8.1 adds REMOVE_PEERING to deletion_policy
    google = {
      source  = "hashicorp/google"
      version = ">= 8.1, < 9.0"
    }
  }
}
