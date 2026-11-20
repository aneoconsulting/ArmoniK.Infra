terraform {
  required_version = ">= 1.17.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.59"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.1, < 3.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12"
    }
  }
}
