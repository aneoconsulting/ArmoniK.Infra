locals {
  # Better error handling for MongoDB connection availability
  mongodb_connection_available = try(length(data.mongodbatlas_advanced_cluster.aklocal.connection_strings) > 0, false)
  mongodb_url                  = local.mongodb_connection_available ? regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<dns>[^/?#]*))", data.mongodbatlas_advanced_cluster.aklocal.connection_strings[0].standard_srv) : { scheme = "mongodb+srv", dns = "unavailable" }
  mongodb_port                 = 27017 # Standard MongoDB port

  # Single source of truth for database configuration
  mongodb_database_name = "database"
  mongodb_auth_source   = "admin"

  # Certificate information
  mongodb_ca_cert_available = fileexists("${path.module}/certs/ca.pem")
  # mongodb_ca_cert_path      = local.mongodb_ca_cert_available ? "/mongodb/certificate/mongodb-ca-cert" : ""

  atlas_outputs = {
    env_from_secret = {
      "MongoDB__User" = {
        "secret" = kubernetes_secret.mongodb_admin.metadata[0].name
        "field"  = "username"
      }
      "MongoDB__Password" = {
        secret = kubernetes_secret.mongodb_admin.metadata[0].name
        field  = "password"
      }
      "MongoDB__ConnectionString" = {
        secret = kubernetes_secret.mongodbatlas_connection_string.metadata[0].name
        field  = "string"
      }
      "MongoDB__CAFile" = local.mongodb_ca_cert_available ? {
        secret = kubernetes_secret.mongodb_atlas_certificates[0].metadata[0].name
        field  = "mongodb-ca-cert"
      } : null
    }

    env = {
      "Components__TableStorage"  = "ArmoniK.Adapters.MongoDB.TableStorage"
      "MongoDB__Host"             = local.mongodb_url.dns
      "MongoDB__Tls"              = "true"
      "MongoDB__DatabaseName"     = local.mongodb_database_name
      "MongoDB__DirectConnection" = "false"
      "MongoDB__AuthSource"       = local.mongodb_auth_source
    }
  }
}
