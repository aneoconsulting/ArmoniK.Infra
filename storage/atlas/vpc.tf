resource "aws_vpc_endpoint" "mongodb_atlas" {
  vpc_id              = var.vpc_id
  service_name        = mongodbatlas_privatelink_endpoint.pe.endpoint_service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = var.security_group_ids
  private_dns_enabled = false


  tags = merge(
    var.tags,
    { Name = "${local.tags["Name"]}-mongodb-atlas" }
  )
  depends_on = [mongodbatlas_privatelink_endpoint.pe]
}

resource "mongodbatlas_privatelink_endpoint" "pe" {
  project_id    = var.project_id
  provider_name = "AWS"
  region        = var.region

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      provider_name,
      region,
      id
    ]
  }
}

resource "mongodbatlas_privatelink_endpoint_service" "pe_service" {
  project_id          = mongodbatlas_privatelink_endpoint.pe.project_id
  private_link_id     = mongodbatlas_privatelink_endpoint.pe.id
  endpoint_service_id = aws_vpc_endpoint.mongodb_atlas.id
  provider_name       = "AWS"

  depends_on = [
    mongodbatlas_privatelink_endpoint.pe,
    aws_vpc_endpoint.mongodb_atlas
  ]
}
