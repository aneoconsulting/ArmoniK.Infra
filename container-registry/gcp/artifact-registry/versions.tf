terraform {
  required_version = ">= 1.9"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.0, < 9.0"
    }
    # google_project_service_identity only exists in google-beta
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 8.0, < 9.0"
    }
  }
}
