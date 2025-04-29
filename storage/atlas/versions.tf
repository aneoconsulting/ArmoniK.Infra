terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.21.1"
    }
  }
  required_version = ">= 1.0"
}
