terraform {
  required_version = ">= 1.5.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
    # google_project_service_identity only exists in google-beta
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12"
    }
  }
}
