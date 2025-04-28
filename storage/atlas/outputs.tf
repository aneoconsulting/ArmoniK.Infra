locals {
  private_endpoints = flatten([for cs in data.mongodbatlas_advanced_cluster.akaws.connection_strings : cs.private_endpoint])

  connection_strings = [
    for pe in local.private_endpoints : pe.srv_connection_string
    if contains([for e in pe.endpoints : e.endpoint_id], aws_vpc_endpoint.vpce.id)
  ]
  connection_string = length(local.connection_strings) > 0 ? local.connection_strings[0] : ""
  mongodb_url       = regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<dns>[^/?#]*))", local.connection_string)

}

output "connection_string" {
  description = "MongoDB Atlas connection string using the private endpoint." # Add description
  value       = local.connection_string
  sensitive   = true
}
