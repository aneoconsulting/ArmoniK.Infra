provider "google" {
  project = var.project
  region  = var.region
}

terraform {
  required_version = ">= 1.11.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.75.0"
    }
  }
}
