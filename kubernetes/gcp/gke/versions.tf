terraform {
  required_version = ">= 1.5.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.9"
    }
    # google_project_service_identity only exists in google-beta
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 8.9"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2"
    }
  }
}
