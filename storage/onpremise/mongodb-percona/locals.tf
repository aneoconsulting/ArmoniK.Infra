locals {
  # The Percona operator creates a service with a predictable name pattern:
  #   <cluster-release-name>-psmdb-db-rs0   (for replica set, no sharding)
  #   <cluster-release-name>-psmdb-db-mongos (mongos, sharded)
  #   <cluster-release-name>-psmdb-db-cfg0  (for config server, sharded)
  cluster_release_name = "${var.name}-db-ps"
  secrets_name     = "${local.cluster_release_name}-secrets"
  ssl_secret_name  = "${local.cluster_release_name}-ssl"

  mongodb_dns = var.sharding != null && var.sharding.enabled ? (
    "${local.cluster_release_name}-mongos.${var.namespace}.svc.cluster.local"
    ) : (
    "${local.cluster_release_name}-rs0.${var.namespace}.svc.cluster.local"
  )

  mongodb_port = 27017
  mongodb_connection_params = var.sharding != null && var.sharding.enabled ? "" : "&directConnection=true"
  mongodb_url  = "mongodb://${local.mongodb_dns}:${local.mongodb_port}/${var.cluster.database_name}?authSource=admin"
}
