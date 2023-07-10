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
  config_path    = var.kub_config_path
  config_context = var.kub_config_context
}
