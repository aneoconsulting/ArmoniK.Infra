terraform {
  required_version = ">= 1.11.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"
    }
  }
}
