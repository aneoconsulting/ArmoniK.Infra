terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.4.0"
    }
  }
}
