# AWS provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

terraform {
  required_version = ">= 1.13.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.21.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10.1, < 3.0.0"
    }
  }
}
