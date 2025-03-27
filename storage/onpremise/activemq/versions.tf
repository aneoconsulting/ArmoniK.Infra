terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.36.0"
    }
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = ">= 0.2.5"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.2"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.6"
    }
  }
}
