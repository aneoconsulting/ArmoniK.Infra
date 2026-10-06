terraform {
  required_version = ">= 1.16.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.75.0"
    }
  }
}
