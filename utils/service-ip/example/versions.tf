terraform {
  required_version = ">= 1.14.4"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"
    }
  }
}
