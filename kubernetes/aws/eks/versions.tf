terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.99.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.37.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.4"
    }
  }
}
