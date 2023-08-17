Google and third parties (together known as service producers) can offer services that are hosted in a VPC network. Private services access lets you reach the internal IP addresses of these Google and third-party services by using private connections. This is useful if you want your VM instances in your VPC network to use internal IP addresses instead of external IP addresses. The official documentation for [Private service access](https://cloud.google.com/vpc/docs/private-services-access).


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
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_compute_network.peering_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_global_address_adress_type"></a> [global\_address\_adress\_type](#input\_global\_address\_adress\_type) | The type of address to reserve. | `string` | `"EXTERNAL"` | no |
| <a name="input_global_address_description"></a> [global\_address\_description](#input\_global\_address\_description) | An optional description for the global\_address resource | `string` | `null` | no |
| <a name="input_global_address_ip"></a> [global\_address\_ip](#input\_global\_address\_ip) | The static IP represented by this resources. | `string` | n/a | yes |
| <a name="input_global_address_ip_version"></a> [global\_address\_ip\_version](#input\_global\_address\_ip\_version) | The IP version that will be used by this address. | `string` | n/a | yes |
| <a name="input_global_address_name"></a> [global\_address\_name](#input\_global\_address\_name) | Name of the resource. | `string` | n/a | yes |
| <a name="input_global_address_prefix_length"></a> [global\_address\_prefix\_length](#input\_global\_address\_prefix\_length) | The prefix length if the resource represents an IP range. | `number` | `0` | no |
| <a name="input_global_address_purpose"></a> [global\_address\_purpose](#input\_global\_address\_purpose) | The purpose of this resource | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The private service access to create | `string` | n/a | yes |
| <a name="input_vpc_network"></a> [vpc\_network](#input\_vpc\_network) | The vpc\_network on which the psa will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_peering_network"></a> [peering\_network](#output\_peering\_network) | The VPC that the PSA will use |
| <a name="output_private_ip_alloc"></a> [private\_ip\_alloc](#output\_private\_ip\_alloc) | The IP address reserved for the VPC |
| <a name="output_private_service_access"></a> [private\_service\_access](#output\_private\_service\_access) | The PSA |
<!-- END_TF_DOCS -->