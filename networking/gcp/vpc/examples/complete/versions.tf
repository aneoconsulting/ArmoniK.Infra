# GCP provider
provider "google" {
  project = var.project
  region  = var.region
}

terraform {
  required_version = ">= 1.13.1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.16.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }
}
