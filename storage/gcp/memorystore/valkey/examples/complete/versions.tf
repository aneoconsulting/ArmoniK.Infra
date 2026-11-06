provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}

provider "kubernetes" {
  config_path = var.kube_config_path
}

terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.10"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 8.10"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
}
