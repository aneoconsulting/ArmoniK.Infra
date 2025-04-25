locals {
  private_endpoints = flatten([for cs in data.mongodbatlas_advanced_cluster.akaws.connection_strings : cs.private_endpoint])

  connection_strings = [
    for pe in local.private_endpoints : pe.srv_connection_string
    if contains([for e in pe.endpoints : e.endpoint_id], var.vpce_mongodb_atlas_endpoint_id)
  ]

  connection_string = length(local.connection_strings) > 0 ? local.connection_strings[0] : ""
  mongodb_url       = regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<dns>[^/?#]*))", local.connection_string)

  atlas_outputs = {
    env_from_secret = {
      "MongoDB__User" = {
        secret = kubernetes_secret.mongodb_admin.metadata[0].name
        field  = "username"
      }
      "MongoDB__Password" = {
        secret = kubernetes_secret.mongodb_admin.metadata[0].name
        field  = "password"
      }
      "MongoDB__ConnectionString" = {
        secret = kubernetes_secret.mongodbatlas_connection_string.metadata[0].name
        field  = "string"
      }
    }

    env = {
      "Components__TableStorage" = "ArmoniK.Adapters.MongoDB.TableStorage"
      "MongoDB__Host"            = local.mongodb_url.dns
      #"MongoDB__Port"             = "27017" # Port is usually included in SRV string
      "MongoDB__Tls"              = "true"
      #"MongoDB__ReplicaSet"       = "rs0" # Replica set name might be in SRV string or specific to cluster
      "MongoDB__DatabaseName"     = "database"
      "MongoDB__DirectConnection" = "false"
      #"MongoDB__CAFile"           = "/mongodb/certificate/mongodb-ca-cert" # CA file handling depends on deployment
      "MongoDB__AuthSource"       = "admin"
      "MongoDB__Sharding"         = "true" # Assuming sharding based on original config
    }
  }
}