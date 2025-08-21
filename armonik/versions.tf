terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0, < 3.0.0"
    }
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = ">= 0.2.5"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.1.0"
    }
  }
}
