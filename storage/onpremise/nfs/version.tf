terraform {
  required_version = ">= 1.13.1"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"

    }
  }

}
