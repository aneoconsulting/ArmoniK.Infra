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
      version = ">= 5.92.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.3"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
  }
}
