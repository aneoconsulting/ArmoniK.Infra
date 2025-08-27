terraform {
  required_version = ">= 1.13.1"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.1, < 3.0.0"
    }
  }
}
