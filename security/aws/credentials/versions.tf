terraform {
  required_version = ">= 1.14.4"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4.3"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
  }
}
