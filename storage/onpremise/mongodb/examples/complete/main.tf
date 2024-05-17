module "complete_mongodb_instance" {
  source            = "../../"
  namespace         = var.namespace
  helm_release_name = "mongodb-armonik-helm-release"
  kube_config_path  = "~/.kube/config"
  mTLSEnabled       = false

  labels = {
    "app"  = "storage"
    "type" = "table"
  }

  mongodb = {
    architecture       = "replicaset"
    databases_names    = ["database"]
    helm_chart_version = "15.1.4"
    image              = "mongo"
    image_pull_secrets = [""]
    node_selector      = {}
    registry           = "docker.io"
    replicas_number    = 2
    tag                = "6.0.7"
  }

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
}
