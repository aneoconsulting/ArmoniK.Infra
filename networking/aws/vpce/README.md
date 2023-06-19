# AWS VPC endpoints

This module provides a VPC endpoints in a given AWS VPC.

Give for each endpoint object the following information:

* `vpc_id`: (Required) The ID of the VPC in which the endpoint will be used.
* `service`: (Optional) Common name of an AWS service (e.g., `s3`).
* `auto_accept`: (Optional) Accept the VPC endpoint (the VPC endpoint and service need to be in the same AWS account).
* `policy`: (Optional) A policy to attach to the endpoint that controls access to the service. This is a JSON formatted
  string. Defaults to full access. All `Gateway` and some `Interface` endpoints support policies - see the [relevant AWS
  documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-access.html) for more details. For more
  information about building AWS IAM policy documents with Terraform, see
  the [AWS IAM Policy Document Guide](https://developer.hashicorp.com/terraform/tutorials/aws/aws-iam-policy).
* `private_dns_enabled`: (Optional; AWS services and AWS Marketplace partner services only) Whether to associate a
  private hosted zone with the specified VPC. Applicable for endpoints of type `Interface`. Defaults to `false`
* `ip_address_type`: (Optional) The IP address type for the endpoint. Valid values are `ipv4`, `dualstack`, and `ipv6`.
* `route_table_ids`: (Optional) One or more route table IDs. Applicable for endpoints of type `Gateway`.
* `subnet_ids`: (Optional) The ID of one or more subnets in which to create a network interface for the endpoint. Applicable
  for endpoints of type `GatewayLoadBalancer` and `Interface`.
* `security_group_ids`: (Optional) The ID of one or more security groups to associate with the network interface. Applicable
  for endpoints of type `Interface`. If no security groups are specified, the
  VPC's [default security group](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html#DefaultSecurityGroup)
  is associated with the endpoint.
* `tags`: (Optional) A map of tags to assign to the resource. If configured with a provider `default_tags configuration
  block present, tags with matching keys will overwrite those defined at the provider-level.
* `vpc_endpoint_type`: (Optional) The VPC endpoint type, `Gateway`, `GatewayLoadBalancer`, or `Interface`. Defaults
  to `Interface`.

