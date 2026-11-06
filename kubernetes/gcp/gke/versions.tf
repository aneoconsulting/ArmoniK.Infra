terraform {
  required_version = ">= 1.17.1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.9"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2"
    }
  }
}
