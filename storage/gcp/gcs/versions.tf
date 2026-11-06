terraform {
  required_version = ">= 1.5.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 8.10.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.4.0"
    }
  }
}
