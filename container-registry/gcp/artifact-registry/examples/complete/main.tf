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
    "roles/artifactregistry.repoAdmin" = ["user:lzianekhodja@aneo.fr"],
    "roles/artifactregistry.reader"    = ["user:hbitoun@aneo.fr", "user:lzianekhodja@aneo.fr", "user:flecomte@aneo.fr"],
    "roles/artifactregistry.writer"    = ["user:aabla@aneo.fr", "user:flecomte@aneo.fr"]
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
  source         = "../../../artifact-registry"
  docker_images  = local.docker_images
  name           = "complete-test"
  description    = "A complete artifact registry"
  immutable_tags = true
  kms_key_name   = null
  iam_bindings   = local.registry_iam
  labels = {
    env             = "test"
    app             = "complete"
    module          = "GCP Artifact Registry"
    "create_by"     = "me"
    "creation_date" = null_resource.timestamp.triggers["date"]
  }
}
