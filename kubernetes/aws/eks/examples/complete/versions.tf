# AWS provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.99.1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.4"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
  }
}
