terraform {
  required_version = ">= 1.16.3"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"

    }
  }

}
