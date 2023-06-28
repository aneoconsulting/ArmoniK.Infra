terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.21.1"
    }
  }
}
provider "kubernetes" {
  config_path    = "/home/adem/.kube/config"
  config_context = "default"
}
