locals {
  docker_images = {
    prometheus = {
      image = "prom/prometheus"
      tag   = "1.5.0"
    },
    node-exporter = {
      image = "prom/node-exporter"
      tag   = "latest"
    },
    redis = {
      image = "redis"
      tag   = "6.0.20"
    },
    grafana = {
      image = "grafana/grafana"
      tag   = "9.5.6"
    },
    nginx = {
      image = "nginx"
      tag   = "stable"
    },
    rabbitmq = {
      image = "rabbitmq"
      tag   = "latest"
    },
    busybox = {
      image = "busybox"
      tag   = "stable"
    }

  }

  labels = {
    label_key_1 = "value-label-1",
    label_key_2 = "value-label-2",
    label_key_3 = "value-label-3"
  }

  registry_iam = {
    "roles/artifactregistry.repoAdmin" = ["user:user1@example.com"],
    "roles/artifactregistry.reader"    = ["user:user2@example.com", "user:user3@example.com", "user:user4@example.com"],
    "roles/artifactregistry.writer"    = ["user:user2@example.com", "user:user3@example.com"]
  }
}

module "complete_artifact_registry" {
  source               = "../../../artifact-registry"
  docker_images        = local.docker_images
  name                 = "complete"
  labels               = local.labels
  description          = "A complete artifact registry"
  immutable_tags       = true
  kms_key_name         = null
  iam_bindings         = local.registry_iam
}
