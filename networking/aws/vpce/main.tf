locals {
  tags = merge(var.tags, { module = "vpce" })
}

# Get the service name of each the VPC endpoints
data "aws_vpc_endpoint_service" "endpoints" {
  for_each = var.endpoints
  service  = try(each.value["service"], null)
  filter {
    name   = "service-type"
    values = [try(each.value["vpc_endpoint_type"], "Interface")]
  }
}

# Create the VPC endpoints
resource "aws_vpc_endpoint" "endpoints" {
  for_each            = var.endpoints
  service_name        = data.aws_vpc_endpoint_service.endpoints[each.key].service_name
  vpc_id              = var.vpc_id
  auto_accept         = try(each.value["auto_accept"], null)
  policy              = try(each.value["policy"], null)
  private_dns_enabled = try(each.value["vpc_endpoint_type"], "") == "Interface" ? try(each.value["private_dns_enabled"], false) : false
  ip_address_type     = try(each.value["ip_address_type"], null)
  route_table_ids     = try(each.value["vpc_endpoint_type"], "") == "Gateway" ? try(each.value["route_table_ids"], null) : null
  subnet_ids          = contains(["GatewayLoadBalancer", "Interface"], try(each.value["vpc_endpoint_type"], "")) ? (distinct(compact(concat(var.subnet_ids, try(each.value["subnet_ids"], []))))) : null
  security_group_ids  = try(each.value["vpc_endpoint_type"], "") == "Interface" ? (distinct(compact(concat(var.security_group_ids, try(each.value["security_group_ids"], []))))) : null
  vpc_endpoint_type   = try(each.value["vpc_endpoint_type"], "Interface")
  tags                = merge(try(each.value["tags"], null), local.tags)
  timeouts {
    create = try(var.timeouts["create"], "10m")
    update = try(var.timeouts["update"], "10m")
    delete = try(var.timeouts["delete"], "10m")
  }
}
