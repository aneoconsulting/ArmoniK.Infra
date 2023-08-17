# GCP provider
provider "google" {
  project = var.project
  region  = var.region
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.75.0, < 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
  }
}
