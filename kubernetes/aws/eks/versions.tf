terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.72.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0, < 3.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.3.2"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.14.2"
    }
  }
}
