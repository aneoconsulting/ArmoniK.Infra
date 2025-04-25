locals {
  # MongoDB connection information
  mongodb_database_name = "database"
  mongodb_auth_source   = "admin"

  # Determine whether to use the private endpoint data source
  use_private_endpoint = var.enable_private_endpoint && var.aws_endpoint_id != "" && length(try(data.mongodbatlas_advanced_cluster.akaws, [])) > 0
  
  # Get connection data from appropriate data source
  connection_data = local.use_private_endpoint ? data.mongodbatlas_advanced_cluster.akaws[0] : data.mongodbatlas_advanced_cluster.aklocal
  
  # Handle connection URL parsing for both public and private endpoints
  # Check for connection availability
  mongodb_connection_available = try(length(local.connection_data.connection_strings) > 0, false)
  
  # Get public connection string
  public_connection_string = local.mongodb_connection_available ? try(local.connection_data.connection_strings[0].standard_srv, "") : ""
  public_mongodb_url = local.public_connection_string != "" ? regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<dns>[^/?#]*))", local.public_connection_string) : { scheme = "mongodb+srv", dns = "unavailable" }
  
  # Private endpoint handling (only if enabled)
  private_endpoints = local.use_private_endpoint ? flatten([
    for cs in try(local.connection_data.connection_strings, []) : 
    try(cs.private_endpoint, [])
  ]) : []
  
  # Find relevant private connection strings that match our endpoint
  connection_strings = local.use_private_endpoint ? [
    for pe in local.private_endpoints : pe.srv_connection_string
    if contains([for e in try(pe.endpoints, []) : e.endpoint_id], var.aws_endpoint_id)
  ] : []
  
  # Use the first private connection string if available
  private_connection_string = length(local.connection_strings) > 0 ? local.connection_strings[0] : ""
  private_mongodb_url = local.private_connection_string != "" ? regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<dns>[^/?#]*))", local.private_connection_string) : { scheme = "mongodb+srv", dns = "unavailable" }
  
  # Select the appropriate URL based on whether private endpoint is available
  mongodb_url = local.private_connection_string != "" ? local.private_mongodb_url : local.public_mongodb_url

  # Rest of your locals remain unchanged
  # Certificate information
  mongodb_ca_cert_available = fileexists("${path.module}/certs/ca.pem")
  mongodb_ca_cert_path = local.mongodb_ca_cert_available ? "/mongodb/certificate/mongodb-ca-cert" : ""

  # Atlas outputs for environment variables and secrets
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
      # Only include certificate reference if available
      "MongoDB__CAFile" = local.mongodb_ca_cert_available ? {
        secret = try(kubernetes_secret.mongodb_atlas_certificates[0].metadata[0].name, "mongodb-atlas-certificates")
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
      # "MongoDB__Sharding"         = "true"
      # Add certificate path if available
      "MongoDB__CAFile"           = local.mongodb_ca_cert_available ? local.mongodb_ca_cert_path : null
    }
  }
}