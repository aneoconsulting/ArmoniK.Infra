terraform {
  required_version = ">= 1.16.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61"
    }
  }
}
