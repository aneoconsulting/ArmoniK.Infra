terraform {
  required_version = ">= 1.0"

  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = ">= 1.38.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.37.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.100.0"
    }
  }
}
