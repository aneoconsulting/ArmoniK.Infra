# We'll use a different approach for handling existing endpoints
# Since older provider versions don't support the data source "mongodbatlas_privatelink_endpoints"

locals {
  private_endpoints = flatten([for cs in data.mongodbatlas_advanced_cluster.akaws.connection_strings : cs.private_endpoint])

  # Always start with attempt to create new endpoint in main.tf (with count conditional)
  # We'll handle existing endpoints through error handling in the resource
  effective_endpoint_id = aws_vpc_endpoint.mongodb_atlas.id
  # If the endpoint was created, use it
  connection_strings = [
    for pe in local.private_endpoints : pe.srv_connection_string
    if contains([for e in pe.endpoints : e.endpoint_id], local.effective_endpoint_id)
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.namespace}-${var.cluster_name}-mongodb-atlas"
    }
  )

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
      "Components__TableStorage"  = "ArmoniK.Adapters.MongoDB.TableStorage"
      "MongoDB__Host"             = local.mongodb_url.dns
      "MongoDB__Tls"              = "true"
      "MongoDB__DatabaseName"     = "database"
      "MongoDB__DirectConnection" = "false"
      "MongoDB__AuthSource"       = "admin"
      "MongoDB__Sharding"         = "false" # Depending on the sharding strategy, this may need to be set to true
    }
  }
}
