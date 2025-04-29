# Create a VPC endpoint for MongoDB Atlas
resource "aws_vpc_endpoint" "mongodb_atlas" {
  count              = var.endpoint_id == null ? 1 : 0
  vpc_id             = var.vpc_id
  service_name       = mongodbatlas_privatelink_endpoint.pe.endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = data.aws_subnets.private.ids
  security_group_ids = [data.aws_security_group.default.id]

  tags = {
    Name = "atlas-mongodb-endpoint"
  }
}


# Get the default security group
data "aws_security_group" "default" {
  vpc_id = var.vpc_id
  name   = "default"
}

# Get private subnets
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  # Optional filter for private subnets
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

locals {
  effective_endpoint_id = coalesce(var.endpoint_id, try(aws_vpc_endpoint.mongodb_atlas[0].id, null))
}
