module "complete_mongodb_instance" {
  source    = "../../"
  namespace = var.namespace
  name      = "mongodb-armonik-helm-release"
  timeout   = 300

  labels = {
    "app"  = "storage"
    "type" = "table"
  }

  mongodb = {
    helm_chart_repository = "oci://registry-1.docker.io/bitnamicharts"
    helm_chart_name       = "mongodb"
    helm_chart_version    = "15.6.12"
    image                 = "bitnami/mongodb"
    image_pull_secrets    = [""]
    node_selector         = {}
    registry              = "docker.io"
    replicas              = 2
    tag                   = "7.0.12-debian-12-r0"
  }

  mongodb_resources = {
    limits = {
      memory = "900Mi"
    }
  }

  arbiter_resources = {
    requests = {
      "cpu" = "300m"
    }
  }

  persistent_volume = {
    access_mode         = ["ReadWriteOnce"]
    reclaim_policy      = "Delete"
    storage_provisioner = "rancher.io/local-path"
    volume_binding_mode = "WaitForFirstConsumer"
    parameters          = {}

    resources = {
      requests = {
        storage = "2Gi"
      }
    }
  }

  security_context = {
    run_as_user = 9001
    fs_group    = 9001
  }
}
