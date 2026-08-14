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
      version = "~> 5.100"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.4.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.3.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.0"
    }
  }
}
