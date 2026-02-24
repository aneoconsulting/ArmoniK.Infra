locals {
  # The Percona operator creates a service with a predictable name pattern:
  #   <cluster-release-name>-psmdb-db-rs0   (for replica set, no sharding)
  #   <cluster-release-name>-psmdb-db-mongos (mongos, sharded)
  #   <cluster-release-name>-psmdb-db-cfg0  (for config server, sharded)
  cluster_release_name = "${var.name}-db-ps"

  secrets_name             = "${local.cluster_release_name}-secrets"
  ssl_secret_name          = "${local.cluster_release_name}-ssl"
  ssl_internal_secret_name = "${local.cluster_release_name}-ssl-internal"

  mongodb_dns = var.sharding != null && var.sharding.enabled ? (
    "${local.cluster_release_name}-mongos.${var.namespace}.svc.cluster.local"
    ) : (
    "${local.cluster_release_name}-rs0.${var.namespace}.svc.cluster.local"
  )

  mongodb_port              = 27017
  mongodb_connection_params = var.sharding != null && var.sharding.enabled ? "" : "?replicaSet=rs0"
  mongodb_url               = "mongodb://${local.mongodb_dns}:${local.mongodb_port}/${var.cluster.database_name}?authSource=admin"

  shards_volume_spec = var.persistence != null ? {
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
    emptyDir = null
    } : {
    persistentVolumeClaim = null
    emptyDir              = {}
  }

  configsvr_volume_spec = var.persistence != null ? {
    persistentVolumeClaim = {
      storageClassName = try(
        coalesce(var.persistence.configsvr.storage_class_name),
        length(kubernetes_storage_class.configsvr) > 0 ? kubernetes_storage_class.configsvr[0].metadata[0].name : null,
        null
      )
      resources = {
        requests = { storage = var.persistence.configsvr.storage_size }
      }
      emptyDir = null
    }
    } : {
    persistentVolumeClaim = null
    emptyDir              = {}
  }
}
