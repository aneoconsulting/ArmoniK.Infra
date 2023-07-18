locals {
  registry_images = {
    prometheus = {
      image = "prom/prometheus"
      tag   = "1.5.0"
    }
  }

  registry_lables = {
    label-test = "test"
  }
}

module "simple_artifact_registry" {
  source               = "../../../artifactory"
  registry_images      = local.registry_images
  project_id           = "my-project-id"
  credentials_file     = "/home/hbitoun/.config/gcloud/application_default_credentials.json"
  registry_name        = "test"
  registry_description = "un registry"
  region               = "europe-west9"
}