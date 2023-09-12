Google and third parties (together known as service producers) can offer services that are hosted in a VPC network. Private services access lets you reach the internal IP addresses of these Google and third-party services by using private connections. This is useful if you want your VM instances in your VPC network to use internal IP addresses instead of external IP addresses. The official documentation for [Private service access](https://cloud.google.com/vpc/docs/private-services-access).

This module is used in ArmoniK to create a VPC for the memorystore service. 
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.51.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.51.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_global_address.private_ip_alloc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_service_networking_connection.private_service_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_networking_connection) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adress_type"></a> [adress\_type](#input\_adress\_type) | The type of address to reserve. | `string` | `"INTERNAL"` | no |
| <a name="input_description"></a> [description](#input\_description) | An optional description for the global\_address resource | `string` | `null` | no |
| <a name="input_ip"></a> [ip](#input\_ip) | The static IP represented by this resources. | `string` | `null` | no |
| <a name="input_ip_version"></a> [ip\_version](#input\_ip\_version) | The IP version that will be used by this address. | `string` | `"IPV4"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the resource. | `string` | n/a | yes |
| <a name="input_prefix_length"></a> [prefix\_length](#input\_prefix\_length) | The prefix length if the resource represents an IP range. | `number` | `null` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The private service access to create | `string` | `"servicenetworking.googleapis.com"` | no |
| <a name="input_vpc_link"></a> [vpc\_link](#input\_vpc\_link) | The vpc on which the psa will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_ip_alloc"></a> [private\_ip\_alloc](#output\_private\_ip\_alloc) | The IP address reserved for the VPC |
| <a name="output_private_service_access"></a> [private\_service\_access](#output\_private\_service\_access) | The PSA |
<!-- END_TF_DOCS -->