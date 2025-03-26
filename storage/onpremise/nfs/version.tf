terraform {
  required_version = ">= 1.11.3"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"

    }
  }

}
