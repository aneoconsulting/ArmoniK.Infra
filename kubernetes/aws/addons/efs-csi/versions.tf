terraform {
  required_version = ">= 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.3.0, < 4.0.0"
    }
  }
}
