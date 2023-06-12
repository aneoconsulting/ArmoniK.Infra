terraform {
  required_providers {
    required_version = ">= 1.0"
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.0"
    }
  }
}
