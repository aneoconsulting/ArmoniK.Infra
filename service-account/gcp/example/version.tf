# provider "kubernetes" {
#   host                   = module.gke.endpoint
#   cluster_ca_certificate = base64decode(module.gke.ca_certificate)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "gcloud"
#     # This requires the gcloud cli to be installed locally where Terraform is executed
#     args = ["container", "clusters", "get-credentials", module.gke.name, "--project=${var.project_id}", "--region=${var.region}"]
#   }
# }
data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  token                  = data.google_client_config.current.access_token
}

# GCP provider
provider "google" {
  project = var.project_id
  region  = var.region
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.75.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.21.1"
    }
  }
}
