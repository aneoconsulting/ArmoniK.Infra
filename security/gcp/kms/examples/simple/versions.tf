terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.50.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}
