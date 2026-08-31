terraform {
  required_version = ">= 1.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0, < 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.4.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.9.0"
    }
  }
}
