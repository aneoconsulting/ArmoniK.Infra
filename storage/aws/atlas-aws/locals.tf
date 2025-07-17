locals {
  private_endpoints = flatten([for cs in data.mongodbatlas_advanced_cluster.atlas.connection_strings : cs.private_endpoint])

  connection_strings = [
    for pe in local.private_endpoints : pe.srv_connection_string
    if contains([for e in pe.endpoints : e.endpoint_id], aws_vpc_endpoint.mongodb_atlas.id)
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.namespace}-${var.cluster_name}-mongodb-atlas"
    }
  )

  connection_string = length(local.connection_strings) > 0 ? local.connection_strings[0] : ""
  mongodb_url       = regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<dns>[^/?#]*))", local.connection_string)
}
