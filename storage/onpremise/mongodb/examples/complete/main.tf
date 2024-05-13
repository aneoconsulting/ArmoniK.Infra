module "complete_mongodb_instance" {
  source    = "../../"
  namespace = var.namespace

  mongodb = {
    image              = "mongo"
    tag                = "6.0.7"
    node_selector      = {}
    image_pull_secrets = ""
    replicas_number    = 1
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
