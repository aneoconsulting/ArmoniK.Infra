terraform {
  required_version = ">= 1.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.3.1"
    }
  }
}
