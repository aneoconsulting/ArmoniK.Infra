terraform {
  required_version = ">= 1.14.5"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.1, < 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.21.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}
