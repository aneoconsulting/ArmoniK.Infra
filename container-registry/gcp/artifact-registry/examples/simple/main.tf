locals {
  registry_images = {
    prometheus = {
      image = "prom/prometheus"
      tag   = "1.5.0"
    }
  }
}

module "simple_artifact_registry" {
  source               = "../.."
  registry_images      = local.registry_images
  registry_name        = "test"
  registry_description = "un registry"
}
