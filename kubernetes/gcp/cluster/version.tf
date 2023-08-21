terraform {
  required_version = ">=1.0"
  required_providers {

    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
  }
  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-kubernetes-engine/v27.0.0"
  }

}
