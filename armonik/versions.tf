terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.2.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.3.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
  }
}
