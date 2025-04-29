locals {
  private_endpoints = flatten([for cs in data.mongodbatlas_advanced_cluster.akaws.connection_strings : cs.private_endpoint])

  connection_strings = [
    for pe in local.private_endpoints : pe.srv_connection_string
    if contains([for e in pe.endpoints : e.endpoint_id], var.vpc_id)
  ]


  connection_string = length(local.connection_strings) > 0 ? local.connection_strings[0] : ""
  mongodb_url       = local.connection_string != "" ? regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<dns>[^/?#]*))", local.connection_string) : { scheme = "", dns = "" }

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
    # Define the CA certificate mount - Removed as Atlas SRV connection typically doesn't require explicit CA file
    # mount_secret = {
    #   "mongodb-ca-cert" = {
    #     secret = kubernetes_secret.mongodb_ca_cert.metadata[0].name # Assuming this secret holds the CA cert
    #     path   = "/mongodb/certificate/"                            # Mount path inside the container
    #     mode   = "0644"                                             # File permissions
    #     # Optional: specify the key if it's not the default 'ca.pem' or similar
    #     # items = {
    #     #   "ca.pem" = { field = "ca.pem", mode = "0644" } 
    #     # }
    #   }
    # }
    mount_secret = {} # Keep the structure but empty
    env = {
      "Components__TableStorage"  = "ArmoniK.Adapters.MongoDB.TableStorage"
      "MongoDB__Host"             = local.mongodb_url.dns
      "MongoDB__Tls"              = "true"
      "MongoDB__DatabaseName"     = "database"
      "MongoDB__DirectConnection" = "false"
      "MongoDB__AuthSource"       = "admin"
      "MongoDB__Sharding"         = "true"
      # Define the path to the mounted CA file as an environment variable - Removed
      # "MongoDB__CAFile"           = "/mongodb/certificate/ca.pem" # Adjust filename if needed based on the secret key
    }
  }
}
