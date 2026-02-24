
resource "helm_release" "operator" {
  name       = "${var.name}-psmdb-operator"
  namespace  = var.namespace
  chart      = var.operator.helm_chart_name
  repository = var.operator.helm_chart_repository
  version    = var.operator.helm_chart_version
  timeout    = var.timeout

  values = [
    yamlencode({
      annotations  = var.operator.annotations
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
resource "kubectl_manifest" "cluster" {
  depends_on = [
    helm_release.operator,
    kubernetes_secret.ssl,
    kubernetes_secret.ssl_internal,
  ]
  yaml_body = yamlencode({
    apiVersion = "psmdb.percona.com/v1"
    kind       = "PerconaServerMongoDB"
    metadata = {
      name        = local.cluster_release_name
      namespace   = var.namespace
      annotations = var.cluster.annotations
    }
    spec = {
      backup = {
        enabled = false
        image   = "percona/percona-backup-mongodb:2.12.0"
      }

      unsafeFlags = {
        replsetSize = var.cluster.replicas < 3
        mongosSize  = var.sharding != null && var.sharding.enabled ? var.sharding.mongos.replicas < 2 : false
      }

      secrets = {
        users       = local.secrets_name
        ssl         = local.ssl_secret_name
        sslInternal = local.ssl_internal_secret_name
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

          nodeSelector = var.sharding.configsvr.node_selector
          tolerations = [
            for key, value in var.sharding.configsvr.node_selector : {
              key      = key
              operator = "Equal"
              value    = value
              effect   = "NoSchedule"
            }
          ]

          resources = var.resources.configsvr

          volumeSpec = local.configsvr_volume_spec
          } : {
          size         = 2
          resources    = {}
          nodeSelector = {}
          tolerations  = []
          volumeSpec = {
            emptyDir = {}
          }
        }

        mongos = var.sharding != null && var.sharding.enabled ? {
          size = var.sharding.mongos.replicas

          nodeSelector = var.sharding.mongos.node_selector

          tolerations = [
            for key, value in var.sharding.mongos.node_selector : {
              key      = key
              operator = "Equal"
              value    = value
              effect   = "NoSchedule"
            }
          ]

          resources = var.resources.mongos

          } : {
          size         = 0
          nodeSelector = {}
          tolerations  = []
          resources    = {}
        }
      }

      replsets = [
        for i in range(
          var.sharding != null && var.sharding.enabled
          ? var.sharding.shards_quantity
          : 1
          ) : {
          name = "rs${i}"
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

          volumeSpec = local.shards_volume_spec
        }
      ]
    }
  })
}

resource "kubernetes_job" "wait_for_percona" {
  depends_on = [kubectl_manifest.cluster]

  metadata {
    name      = "wait-for-percona-${local.cluster_release_name}"
    namespace = var.namespace
    labels = {
      app     = "percona-mongodb"
      service = "wait-for-database"
    }
  }

  spec {
    backoff_limit = 20

    template {
      metadata {
        name = "wait-for-percona"
        labels = {
          app     = "percona-mongodb"
          service = "wait-for-database"
        }
      }

      spec {
        restart_policy = "OnFailure"

        container {
          name  = "check-mongodb"
          image = var.cluster.tag != null ? "${var.cluster.image}:${var.cluster.tag}" : var.cluster.image

          command = ["/bin/sh", "-c"]
          args = [
            <<-EOT
              set -e
              MAX_ATTEMPTS=$((${var.timeout} / 5))
              ATTEMPT=0

              echo "Waiting for MongoDB to be ready..."

              until mongosh \
                "$MONGO_URI" \
                --eval "
                  const status = rs.status();
                  const healthy = status.members.filter(m => m.health === 1);
                  print('Healthy members: ' + healthy.length + '/' + status.members.length);
                  if (healthy.length < status.members.length) {
                    throw new Error('Not all members healthy yet');
                  }
                  print('Replica set is fully healthy.');
                "; do
                ATTEMPT=$((ATTEMPT + 1))
                if [ "$ATTEMPT" -ge "$MAX_ATTEMPTS" ]; then
                  echo "Timed out waiting for MongoDB to be ready"
                  exit 1
                fi
                echo "Attempt $ATTEMPT/$MAX_ATTEMPTS - MongoDB not ready yet, retrying in 5s..."
                sleep 5
              done

              echo "MongoDB cluster is fully ready."
            EOT
          ]

          env {
            name = "MONGO_URI"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongodb_connection_string.metadata[0].name
                key  = "uri"
              }
            }
          }

          volume_mount {
            name       = "mongo-certs"
            mount_path = "/mongodb/certs"
            read_only  = true
          }
        }

        volume {
          name = "mongo-certs"
          secret {
            secret_name = local.ssl_secret_name
          }
        }
      }
    }
  }

  wait_for_completion = true

  timeouts {
    create = "${var.timeout + 60}s"
  }
}
