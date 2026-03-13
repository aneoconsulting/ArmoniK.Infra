terraform {
  required_version = ">= 1.14.7"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.21.1"
    }
  }
}
