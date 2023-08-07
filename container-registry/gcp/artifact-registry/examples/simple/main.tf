data "external" "static_timestamp" {
  program = ["date", "+{ \"creation_date\": \"%Y/%m/%d %T\" }"]
}

resource "null_resource" "timestamp" {
  triggers = {
    creation_date = data.external.static_timestamp.result.creation_date
  }
  lifecycle {
    ignore_changes = [triggers]
  }
}

locals {
  docker_images = {
    prometheus = {
      image = "prom/prometheus"
      tag   = "1.5.0"
    }
  }
}

module "simple_artifact_registry" {
  source               = "../../../artifact-registry"
  docker_images        = local.docker_images
  name                 = "test"
  description          = "A simple artifact registry"
  labels = {
    env             = "test"
    app             = "simple"
    module          = "GCP Artifact Registry"
    "create by"     = "me"
    "creation_date" = null_resource.timestamp.triggers["creation_date"]
  }
}
