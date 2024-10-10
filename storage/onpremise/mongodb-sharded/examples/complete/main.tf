module "sharded_mongodb" {
  source    = "../../"
  namespace = var.namespace
  name      = "mongodb-sharded"
  timeout   = 300

  labels = {
    shards = {
      "role" = "dataHolder"
    }

    router = {
      "role" = "distributer"
    }

    configsvr = {
      "role" = "metadataHolder"
    }
  }

  mongodb = {
    helm_chart_repository = "oci://registry-1.docker.io/bitnamicharts"
    helm_chart_version    = "8.3.8"
    image_pull_secrets    = [""]
    node_selector         = {}
    registry              = "docker.io"
    tag                   = "7.0.14-debian-12-r0"
  }

  sharding = {
    shards = {
      quantity = 2
      replicas = 2
    }

    configsvr = {
      replicas = 2
    }

    router = {
      replicas = 2
    }
  }

  persistence = {
    shards = {
      access_mode         = ["ReadWriteOnce"]
      reclaim_policy      = "Retain"
      storage_provisioner = "rancher.io/local-path"
      resources = {
        requests = {
          storage = "8Gi"
        }
      }
    }

    configsvr = {
      access_mode         = ["ReadWriteOnce"]
      reclaim_policy      = "Delete"
      storage_provisioner = "rancher.io/local-path"
      resources = {
        requests = {
          storage = "1Gi"
        }
      }
    }
  }

  resources = {
    shards = {
      limits = {
        "cpu"    = "1"
        "memory" = "2Gi"
      }
      requests = {
        "cpu"    = "500m"
        "memory" = "1Gi"
      }
    }

    arbiter = {
      limits = {
        "cpu"    = "500m"
        "memory" = "500Mi"
      }
    }

    configsvr = {
      limits = {
        "cpu"    = "1"
        "memory" = "1Gi"
      }
      requests = {
        "cpu"    = "200m"
        "memory" = "400Mi"
      }
    }

    router = {
      requests = {
        "cpu"    = "400m"
        "memory" = "700Mi"
      }
    }
  }
}
