terraform {
  required_version = ">= 1.13.1"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.75.0"
    }
  }
}
