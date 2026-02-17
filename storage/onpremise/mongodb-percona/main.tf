
resource "helm_release" "operator" {
  name       = "${var.name}-psmdb-operator"
  namespace  = var.namespace
  chart      = var.operator.helm_chart_name
  repository = var.operator.helm_chart_repository
  version    = var.operator.helm_chart_version
  timeout    = var.timeout
}

resource "helm_release" "cluster" {
  name       = local.cluster_release_name
  namespace  = var.namespace
  chart      = var.cluster.helm_chart_name
  repository = var.cluster.helm_chart_repository
  version    = var.cluster.helm_chart_version
  timeout    = var.timeout

  # Wait for the operator to be ready before creating the CR
  depends_on = [helm_release.operator]
  values = [
    yamlencode({
      # >> Disabled features we don't need yet <<
      backup = {
        enabled = false
      }

      finalizers = [] # TODO (NOT GOOD I THINK BUT IDK WHAT TO DO): otherwise I need to patch this in wheneve I destroy cuz it hangs... end me

      # >> Sharding configuration <<
      sharding = {
        enabled   = var.sharding != null ? var.sharding.enabled : false

        configsvrReplSet = var.sharding != null && var.sharding.enabled ? {
          size = var.sharding.configsvr.replicas

          affinity = {
            antiAffinityTopologyKey = "none"
          }

          volumeSpec = {
            pvc = {
              resources = {
                requests = {
                  storage = var.persistence.storage_size
                }
              }
            }
          }
        } : null

        mongos = var.sharding != null && var.sharding.enabled ? {
          size = var.sharding.mongos.replicas

          affinity = {
            antiAffinityTopologyKey = "none"
          }
        } : null
      }
      allowUnsafeConfigurations = true
      unsafeFlags = {
        replsetSize = var.cluster.replicas < 3 
        # tls         = true
        mongosSize  = var.sharding != null && var.sharding.enabled ? var.sharding.mongos.replicas < 2 : false
      }

      # >> TLS configuration <<
      tls = {
        mode = "allowTLS"
        allowInvalidCertificates = true
      }

      # >> Image configuration <<
      image = merge(
        { repository = var.cluster.image },
        var.cluster.tag != null ? { tag = var.cluster.tag } : {}
      )

      # >> User configuration <<
      users = [
        {
        name = "application_user"
        db = var.cluster.database_name
        passwordSecretRef = {
            name = "application-user-password"
            key  = "password"
          }
        roles = [{
          name = "readWrite"
          db = var.cluster.database_name
        },
        {
          name = "dbAdmin"
          db = var.cluster.database_name
        },
        { name = "clusterAdmin", db = "admin" } # I do not like the way this is but this is necessary for sharding on the ArmoniK.Core side of things..
        ]
      }
      ]

      # >> Replica Set configuration <<
      replsets = {
        rs0 = {
          size = var.cluster.replicas
          affinity = {
            antiAffinityTopologyKey = "none"
          }
          volumeSpec = {
            pvc = {
              resources = {
                requests = {
                  storage = var.persistence.storage_size
                }
              }
            }
          }
        }
      }
    })
  ]
}
