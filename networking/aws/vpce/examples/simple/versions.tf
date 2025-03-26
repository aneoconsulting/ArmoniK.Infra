# AWS provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

terraform {
  required_version = ">= 1.11.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.61"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }
}
