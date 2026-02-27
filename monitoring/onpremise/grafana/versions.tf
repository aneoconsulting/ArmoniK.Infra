terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.7.0"
    }
  }
}
