
resource "helm_release" "operator" {
  name       = "${var.name}-psmdb-operator"
  namespace  = var.namespace
  chart      = var.operator.helm_chart_name
  repository = var.operator.helm_chart_repository
  version    = var.operator.helm_chart_version
  timeout    = var.timeout

  values = [
    yamlencode({
      nodeSelector = var.operator.node_selector
      tolerations = [
        for key, value in var.operator.node_selector : {
          key      = key
          operator = "Equal"
          value    = value
          effect   = "NoSchedule"
        }
      ]
    })
  ]

}
resource "kubernetes_manifest" "cluster" {
  depends_on = [helm_release.operator]

  manifest = {
    apiVersion = "psmdb.percona.com/v1"
    kind       = "PerconaServerMongoDB"
    metadata = {
      name      = local.cluster_release_name
      namespace = var.namespace
    }
    spec = {
      backup = {
        enabled = false
        image   = "percona/percona-backup-mongodb:2.12.0"
      }

      allowUnsafeConfigurations = true
      unsafeFlags = {
        replsetSize = var.cluster.replicas < 3
        mongosSize  = var.sharding != null && var.sharding.enabled ? var.sharding.mongos.replicas < 2 : false
      }

      tls = {
        mode                     = "preferTLS"
        allowInvalidCertificates = true
      }

      image = var.cluster.tag != null ? "${var.cluster.image}:${var.cluster.tag}" : var.cluster.image

      users = [
        {
          name = "application_user"
          db   = var.cluster.database_name
          passwordSecretRef = {
            name = "application-user-password"
            key  = "password"
          }
          roles = [
            { name = "readWrite", db = var.cluster.database_name },
            { name = "dbAdmin", db = var.cluster.database_name },
            { name = "clusterAdmin", db = "admin" },
          ]
        }
      ]

      sharding = {
        enabled = var.sharding != null ? var.sharding.enabled : false

        configsvrReplSet = var.sharding != null && var.sharding.enabled ? {
          size = var.sharding.configsvr.replicas
          volumeSpec = {
            persistentVolumeClaim = {
              resources = {
                requests = { storage = var.persistence.storage_size }
              }
            }
          }
        } : {
          size = 0
          volumeSpec = {
            persistentVolumeClaim = {
              resources = {
                requests = { storage = "1Gi" }
              }
            }
          }
        }

        mongos = var.sharding != null && var.sharding.enabled ? {
          size = var.sharding.mongos.replicas
        } : {
          size = 0
        }
      }

      replsets = [
        {
          name = "rs0"
          size = var.cluster.replicas

          affinity = {
            antiAffinityTopologyKey = "none"
          }

          nodeSelector = var.cluster.node_selector

          tolerations = [
            for key, value in var.cluster.node_selector : {
              key      = key
              operator = "Equal"
              value    = value
              effect   = "NoSchedule"
            }
          ]

          resources = var.resources.shards

          volumeSpec = {
            persistentVolumeClaim = {
              storageClassName = try(
                coalesce(var.persistence.shards.storage_class_name),
                length(kubernetes_storage_class.shards) > 0 ? kubernetes_storage_class.shards[0].metadata[0].name : null,
                null
              )
              resources = {
                requests = {
                  storage = var.persistence.shards.storage_size
                }
              }
            }
          }
        }
      ]
    }
  }

  wait {
    condition {
      type   = "ready"
      status = "True"
    }
  }

  timeouts {
    create = "15m"
    update = "15m"
  }
}
