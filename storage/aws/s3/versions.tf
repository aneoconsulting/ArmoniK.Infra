terraform {
  required_version = ">= 1.14.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61"
    }
  }
}
