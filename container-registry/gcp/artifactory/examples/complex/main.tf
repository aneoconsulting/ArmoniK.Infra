locals {
  registry_images = {
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

  registry_labels = {
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

module "simple_artifact_registry" {
  source               = "../../../artifactory"
  registry_images      = local.registry_images
  project_id           = "my_project_id"
  credentials_file     = "~/.config/gcloud/application_default_credentials.json"
  registry_name        = "my_registry"
  registry_labels      = local.registry_labels
  registry_description = "One registry example"
  immutable_tags       = true
  region               = "euope-west9"
  zone                 = "a"
  kms_key              = "my_kms_key"
  registry_iam         = local.registry_iam
}
