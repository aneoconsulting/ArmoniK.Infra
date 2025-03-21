provider "google" {
  project               = var.project
  region                = var.region
  user_project_override = true
  billing_project       = var.project
}

provider "google-beta" {
  project               = var.project
  region                = var.region
  user_project_override = true
  billing_project       = var.project
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.26.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.26.0"
    }
  }
}
