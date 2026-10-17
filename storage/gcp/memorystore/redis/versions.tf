terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.3.0"
    }
  }
}
