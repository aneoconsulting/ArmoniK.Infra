terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.38.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.2.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.8.1"
    }
  }
}
