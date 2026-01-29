terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.1.1, < 4.0.0"
    }
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = ">= 0.0.7"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.4"
    }
  }
}
