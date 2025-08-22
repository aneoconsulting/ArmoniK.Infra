provider "google" {
  project = var.project
  region  = var.region
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.49.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.3"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.4"
    }
  }
}
