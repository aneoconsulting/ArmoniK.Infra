provider "google" {
  project = var.project
  region  = var.region
}

# provider "kubernetes" {
#   depends_on=[module.gke]
#   host                   = "https://${local.endpoint}"
#   token                  = data.google_client_config.current.access_token
#   cluster_ca_certificate = base64decode(local.cluster_ca_certificate)
# }

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }

  }
  required_version = ">= 0.13"
}
