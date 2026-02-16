terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.8.1"
    }
  }
}
