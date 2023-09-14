# GCP Private Service Access

Google and third parties (together known as service producers) can offer services that are hosted in a VPC network. Private
services access (PSA) lets you reach the internal IP addresses of these Google and third-party services by using private
connections. This is useful if you want your VM instances in your VPC network to use internal IP addresses instead of
external IP addresses. The official documentation
for [Private service access](https://cloud.google.com/vpc/docs/private-services-access).


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.75.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.75.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_global_address.reserved_service_range](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_service_networking_connection.private_service_connection](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_networking_connection) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address"></a> [address](#input\_address) | The IP address or beginning of the address range represented by this resource. This can be supplied as an input to reserve a specific address or omitted to allow GCP to choose a valid one for you. | `string` | `null` | no |
| <a name="input_address_type"></a> [address\_type](#input\_address\_type) | The type of the address to reserve. | `string` | `"INTERNAL"` | no |
| <a name="input_description"></a> [description](#input\_description) | An optional description of this resource. | `string` | `null` | no |
| <a name="input_ip_version"></a> [ip\_version](#input\_ip\_version) | The IP version that will be used by this address. | `string` | `"IPV4"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the resource. | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | The URL of the network in which to reserve the IP range. . | `string` | n/a | yes |
| <a name="input_prefix_length"></a> [prefix\_length](#input\_prefix\_length) | The prefix length if the resource represents an IP range. | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_service_access"></a> [private\_service\_access](#output\_private\_service\_access) | The PSA. |
| <a name="output_private_service_access_peering"></a> [private\_service\_access\_peering](#output\_private\_service\_access\_peering) | The name of the VPC Network Peering connection that was created by the service producer. |
| <a name="output_reserved_service_range_id"></a> [reserved\_service\_range\_id](#output\_reserved\_service\_range\_id) | The ID of the reserved service range. |
| <a name="output_reserved_service_range_self_link"></a> [reserved\_service\_range\_self\_link](#output\_reserved\_service\_range\_self\_link) | The URI of of the reserved service range. |
<!-- END_TF_DOCS -->