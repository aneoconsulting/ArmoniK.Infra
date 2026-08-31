terraform {
  required_version = ">= 1.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0, < 3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = ">= 0.4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.9.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.9.0"
    }
  }
}
