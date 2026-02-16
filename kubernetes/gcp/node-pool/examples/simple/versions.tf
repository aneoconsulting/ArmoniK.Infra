provider "google" {
  project = var.project
  region  = var.region
}

terraform {
  required_version = ">= 1.14.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.16.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.21.1"
    }
  }
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  token                  = data.google_client_config.current.access_token
  insecure               = false
}
