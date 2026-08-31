terraform {
  required_version = ">= 1.0"
  required_providers {
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
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.4.0"
    }
  }
}
