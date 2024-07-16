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
    helm_chart_version    = "15.1.4"
    image                 = "bitnami/mongodb"
    image_pull_secrets    = [""]
    node_selector         = {}
    registry              = "docker.io"
    replicas              = 2
    tag                   = "7.0.8-debian-12-r2"
  }

  /* Must be null for now
  persistent_volume = {
    access_mode         = ["ReadWriteOnce"]
    reclaim_policy      = "Retain"
    storage_provisioner = "rancher.io/local-path"
    volume_binding_mode = "WaitForFirstConsumer"
    parameters          = {}

    resources = {
      limits = {
        storage = "1Gi"
      }
      requests = {
        storage = "10Gi"
      }
    }
    wait_until_bound = false
  }

  security_context = {
    run_as_user = 999
    fs_group    = 999
  }
  */
}
