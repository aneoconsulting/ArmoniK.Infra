data "google_client_openid_userinfo" "current" {}

locals {
  docker_images = {
    prometheus = {
      image = "prom/prometheus"
      tag   = "latest"
    },
    node-exporter = {
      image = "prom/node-exporter"
      tag   = "latest"
    },
    redis = {
      image = "redis"
      tag   = "latest"
    },
    grafana = {
      image = "grafana/grafana"
      tag   = "latest"
    },
    nginx = {
      image = "nginx"
      tag   = "latest"
    },
    rabbitmq = {
      image = "rabbitmq"
      tag   = "latest"
    },
    busybox = {
      image = "busybox"
      tag   = "latest"
    }
  }
  registry_iam = {
    "roles/artifactregistry.repoAdmin" = [],
    "roles/artifactregistry.reader"    = [],
    "roles/artifactregistry.writer"    = []
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

module "complete_artifact_registry" {
  source                        = "../../../artifact-registry"
  docker_images                 = local.docker_images
  name                          = "complete-test"
  description                   = "A complete artifact registry"
  immutable_tags                = true
  kms_key_name                  = null
  iam_bindings                  = local.registry_iam
  labels                        = {
                                    env             = "test"
                                    app             = "complete"
                                    module          = "GCP Artifact Registry"
                                    "create_by"     = split("@", data.google_client_openid_userinfo.current.email)[0]
                                    "creation_date" = null_resource.timestamp.triggers["date"]
                                  }
  create_service_account        = true
  service_account_id            = "my-service-account-id-13469"
  service_account_display_name  = "my-service-account-artifact-registry"
  service_account_description   = "The description of the service-account"

}
