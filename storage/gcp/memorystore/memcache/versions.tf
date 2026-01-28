terraform {
  required_version = ">= 1.14.4"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.75.0"
    }
  }
}
