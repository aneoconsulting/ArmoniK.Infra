terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.10.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.14.2"
    }
    # google_project_service_identity only exists in google-beta
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 8.10.0"
    }
  }
}
