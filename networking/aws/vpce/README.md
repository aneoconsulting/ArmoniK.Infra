# AWS VPC endpoints

A VPC endpoint enables customers to privately connect to supported AWS services and VPC endpoint services powered by AWS
PrivateLink. Amazon VPC instances do not require public IP addresses to communicate with resources of the service. Traffic
between an Amazon VPC and a service does not leave the Amazon network.

VPC endpoints are virtual devices. They are horizontally scaled, redundant, and highly available Amazon VPC components that
allow communication between instances in an Amazon VPC and services without imposing availability risks or bandwidth
constraints on network traffic. There are two types of VPC endpoints:

* interface endpoints 
* gateway endpoints

This module provides AWS VPC endpoints in a given AWS VPC.

Give for each endpoint object to be created the following information (variable `endpoints`):

* `service`: (Required) Common name of an AWS service (e.g., `s3`).
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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_vpc_endpoint.endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint_service.endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_endpoints"></a> [endpoints](#input\_endpoints) | A map of interface and/or gateway endpoints containing their properties and configurations. See Section "AWS VPC endpoints" for the different arguments of an endpoint object. | `any` | `{}` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | The IDs of security groups to associate with the network interfaces | `set(string)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The IDs of subnets in which to create the network interfaces for the endpoints | `set(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to use on all resources | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Define maximum timeout for creating, updating, and deleting VPC endpoint resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC in which the endpoint will be used | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Array containing the full resource object and attributes for all endpoints created |
<!-- END_TF_DOCS -->
