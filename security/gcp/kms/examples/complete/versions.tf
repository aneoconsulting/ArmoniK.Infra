terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.50.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.7.0"
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

provider "google" {
  project = var.project
  region  = var.region
}
