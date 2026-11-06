terraform {
  required_version = ">= 1.2"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.4.0"
    }
  }
}
