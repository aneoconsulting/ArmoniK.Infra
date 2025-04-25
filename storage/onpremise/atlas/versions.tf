terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
      # Add version constraint if needed, e.g., version = "~> 1.15"
    }
    random = {
      source = "hashicorp/random"
      # Add version constraint if needed, e.g., version = "~> 3.6"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      # Add version constraint if needed, e.g., version = "~> 2.27"
    }
  }
}

# Provider configuration relies on environment variables MONGODB_ATLAS_PUBLIC_KEY and MONGODB_ATLAS_PRIVATE_KEY
provider "mongodbatlas" {}

# Kubernetes provider configuration is assumed to be handled outside this module
# provider "kubernetes" {}

# Random provider configuration (default)
# provider "random" {}