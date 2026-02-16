terraform {
  required_version = ">= 1.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.8.1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.4"
    }
  }
}
