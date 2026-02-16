terraform {
  required_version = ">= 1.14.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.16.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}
