terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.9.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.9.0"
    }
  }
}
