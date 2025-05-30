terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.37.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.3"
    }
  }
}
