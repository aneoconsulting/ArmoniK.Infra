locals {
  tags = merge(var.tags, { module = "vpce" })
}

# Get the service name of each the VPC endpoints
# Resource and ServiceNetwork endpoints are addressed by ARN instead of a named service, so they have no entry here.
data "aws_vpc_endpoint_service" "endpoints" {
  for_each = {
    for k, v in var.endpoints : k => v
    if !contains(["Resource", "ServiceNetwork"], try(v["vpc_endpoint_type"], "Interface"))
  }
  service = try(each.value["service"], null)
  filter {
    name   = "service-type"
    values = [try(each.value["vpc_endpoint_type"], "Interface")]
  }
}

# Create the VPC endpoints
resource "aws_vpc_endpoint" "endpoints" {
  for_each = var.endpoints
  # Exactly one of service_name, resource_configuration_arn or service_network_arn is required.
  service_name               = contains(["Resource", "ServiceNetwork"], try(each.value["vpc_endpoint_type"], "Interface")) ? null : data.aws_vpc_endpoint_service.endpoints[each.key].service_name
  resource_configuration_arn = try(each.value["vpc_endpoint_type"], "") == "Resource" ? try(each.value["resource_configuration_arn"], null) : null
  service_network_arn        = try(each.value["vpc_endpoint_type"], "") == "ServiceNetwork" ? try(each.value["service_network_arn"], null) : null
  vpc_id                     = var.vpc_id
  auto_accept                = try(each.value["auto_accept"], null)
  policy                     = try(each.value["policy"], null)
  private_dns_enabled        = contains(["Interface", "Resource", "ServiceNetwork"], try(each.value["vpc_endpoint_type"], "")) ? try(each.value["private_dns_enabled"], false) : false
  ip_address_type            = try(each.value["ip_address_type"], null)
  # service_region targets the VPC endpoint service's region; applicable for Interface endpoints only.
  service_region     = try(each.value["vpc_endpoint_type"], "") == "Interface" ? try(each.value["service_region"], null) : null
  route_table_ids    = try(each.value["vpc_endpoint_type"], "") == "Gateway" ? try(each.value["route_table_ids"], null) : null
  subnet_ids         = contains(["GatewayLoadBalancer", "Interface"], try(each.value["vpc_endpoint_type"], "")) ? (distinct(compact(concat(var.subnet_ids, try(each.value["subnet_ids"], []))))) : null
  security_group_ids = try(each.value["vpc_endpoint_type"], "") == "Interface" ? (distinct(compact(concat(var.security_group_ids, try(each.value["security_group_ids"], []))))) : null
  vpc_endpoint_type  = try(each.value["vpc_endpoint_type"], "Interface")
  tags               = merge(try(each.value["tags"], null), local.tags)
  dynamic "dns_options" {
    for_each = try(each.value["dns_options"], null) != null ? [each.value["dns_options"]] : []
    content {
      private_dns_preference        = try(dns_options.value["private_dns_preference"], null)
      private_dns_specified_domains = try(dns_options.value["private_dns_specified_domains"], null)
    }
  }
  timeouts {
    create = try(var.timeouts["create"], "10m")
    update = try(var.timeouts["update"], "10m")
    delete = try(var.timeouts["delete"], "10m")
  }
}
