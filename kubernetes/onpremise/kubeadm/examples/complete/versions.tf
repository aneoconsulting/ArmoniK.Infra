terraform {
  required_version = ">= 1.14.5"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.1"
    }
  }
}
