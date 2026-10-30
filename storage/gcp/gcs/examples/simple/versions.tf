provider "google" {
  project = var.project
  region  = var.region
}

terraform {
  required_version = ">= 1.17.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.16.0"
    }
  }
}
