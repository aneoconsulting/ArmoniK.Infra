terraform {
  required_version = ">= 1.11.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.75.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
  }
}
