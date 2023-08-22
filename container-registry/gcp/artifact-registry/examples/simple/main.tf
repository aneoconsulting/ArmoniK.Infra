locals {
  docker_images = {
    prometheus = {
      image = "prom/prometheus"
      tag   = "v2.46.0"
    }
  }
  date = <<-EOT
#!/bin/bash
set -e
DATE=$(date +%F-%H-%M-%S)
jq -n --arg date "$DATE" '{"date":$date}'
  EOT
}

resource "local_file" "date_sh" {
  filename = "${path.module}/generated/date.sh"
  content  = local.date
}

data "external" "static_timestamp" {
  program     = ["bash", "date.sh"]
  working_dir = "${path.module}/generated"
  depends_on  = [local_file.date_sh]
}

resource "null_resource" "timestamp" {
  triggers = {
    date = data.external.static_timestamp.result.date
  }
  lifecycle {
    ignore_changes = [triggers]
  }
}

data "google_client_openid_userinfo" "current" {}

module "simple_artifact_registry" {
  source        = "../../../artifact-registry"
  docker_images = local.docker_images
  name          = "simple-test"
  description   = "A simple artifact registry"
  labels = {
    env             = "test"
    app             = "simple"
    module          = "GCP Artifact Registry"
    "create_by"     = split("@", data.google_client_openid_userinfo.current.email)[0]
    "creation_date" = null_resource.timestamp.triggers["date"]
  }
  create_service_account = false
}
