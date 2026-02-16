provider "google" {
  project = var.project
  region  = var.region
}

terraform {
  required_version = ">= 1.14.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.16.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.1"
    }
  }
}
