terraform {
  required_version = ">= 1.5.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.12.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.9.1"
    }
  }
}
