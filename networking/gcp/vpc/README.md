# GCP VPC

With Google Virtual Private Cloud networks (Google VPC), you can launch GCP resources in a logically isolated virtual network that
you've defined. This virtual network closely resembles a traditional network that you'd operate in your own data center,
with the benefits of using the scalable infrastructure of GCP.

This module creates a GCP VPC with these constraints:

* By default, the VPC is global
* All subnets are in the same region chosen by user
* List of public and private subnets can be created
* List of private subnets for VPC-native Kubernetes clusters can be created
* All created subnets are of purpose `PRIVATE_RFC_1918`
* Create subnet flow logs in Stackdriver
* All traffic are captured in flow logs
* Subnetwork without external IP addresses can access Google APIs and services by using Private Google Access
* If external access enabled, use a NAT router for public subnets

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
| [google_compute_network.vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_router.routers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.nat_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_compute_subnetwork.gke_subnets](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.subnets](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_create_subnetworks"></a> [auto\_create\_subnetworks](#input\_auto\_create\_subnetworks) | Creation of a subnet for each region automatically | `bool` | `false` | no |
| <a name="input_delete_default_routes_on_create"></a> [delete\_default\_routes\_on\_create](#input\_delete\_default\_routes\_on\_create) | Default routes (0.0.0.0/0) will be deleted immediately after network creation | `bool` | `null` | no |
| <a name="input_enable_google_access"></a> [enable\_google\_access](#input\_enable\_google\_access) | Access Google APIs and services by using Private Google Access | `bool` | `true` | no |
| <a name="input_enable_ula_internal_ipv6"></a> [enable\_ula\_internal\_ipv6](#input\_enable\_ula\_internal\_ipv6) | Enable ULA internal ipv6 on this network | `bool` | `null` | no |
| <a name="input_flow_log_max_aggregation_interval"></a> [flow\_log\_max\_aggregation\_interval](#input\_flow\_log\_max\_aggregation\_interval) | The maximum interval of time during which a flow of packets is captured and aggregated into a flow log | `string` | `"INTERVAL_5_SEC"` | no |
| <a name="input_gke_subnets"></a> [gke\_subnets](#input\_gke\_subnets) | Map of subnets for GKE. Each subnet object contains a CIDR block for nodes, a CIDR block for Pods, a CIDR block for services and a region | <pre>map(object({<br>    nodes_cidr_block    = string<br>    pods_cidr_block     = string<br>    services_cidr_block = string<br>    region              = string<br>  }))</pre> | `{}` | no |
| <a name="input_internal_ipv6_range"></a> [internal\_ipv6\_range](#input\_internal\_ipv6\_range) | Specify the /48 range they want from the google defined ULA prefix fd20::/20 | `string` | `null` | no |
| <a name="input_mtu"></a> [mtu](#input\_mtu) | Maximum Transmission Unit in bytes | `number` | `1460` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the VPC | `string` | n/a | yes |
| <a name="input_network_firewall_policy_enforcement_order"></a> [network\_firewall\_policy\_enforcement\_order](#input\_network\_firewall\_policy\_enforcement\_order) | Set the order that Firewall Rules and Firewall Policies are evaluated | `string` | `"AFTER_CLASSIC_FIREWALL"` | no |
| <a name="input_routing_mode"></a> [routing\_mode](#input\_routing\_mode) | The network-wide routing mode to use | `string` | `"GLOBAL"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | A map of private subnets inside the VPC. Each subnet has a CIDR block, a region, and a boolean set to true if the subnet is public, or false if the subnet is private | <pre>map(object({<br>    cidr_block    = string<br>    region        = string<br>    public_access = bool<br>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway_ipv4"></a> [gateway\_ipv4](#output\_gateway\_ipv4) | The gateway address for default routing out of the network. This value is selected by GCP |
| <a name="output_gke_subnet_cidr_blocks"></a> [gke\_subnet\_cidr\_blocks](#output\_gke\_subnet\_cidr\_blocks) | Map of GKE subnet CIDR blocks |
| <a name="output_gke_subnet_ids"></a> [gke\_subnet\_ids](#output\_gke\_subnet\_ids) | Map of GKE subnet IDs |
| <a name="output_gke_subnet_pod_ranges"></a> [gke\_subnet\_pod\_ranges](#output\_gke\_subnet\_pod\_ranges) | Map of range names and IP CIDR ranges of GKE Pod |
| <a name="output_gke_subnet_self_links"></a> [gke\_subnet\_self\_links](#output\_gke\_subnet\_self\_links) | Map of GKE subnet self links |
| <a name="output_gke_subnet_svc_ranges"></a> [gke\_subnet\_svc\_ranges](#output\_gke\_subnet\_svc\_ranges) | Map of range names and IP CIDR ranges of GKE services |
| <a name="output_id"></a> [id](#output\_id) | The ID of the VPC |
| <a name="output_name"></a> [name](#output\_name) | The name of the VPC |
| <a name="output_private_subnet_cidr_blocks"></a> [private\_subnet\_cidr\_blocks](#output\_private\_subnet\_cidr\_blocks) | List of private subnet CIDR blocks |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | List of private subnet IDs |
| <a name="output_private_subnet_regions"></a> [private\_subnet\_regions](#output\_private\_subnet\_regions) | List of private subnet regions |
| <a name="output_private_subnet_self_links"></a> [private\_subnet\_self\_links](#output\_private\_subnet\_self\_links) | List of private subnet self links |
| <a name="output_public_subnet_cidr_blocks"></a> [public\_subnet\_cidr\_blocks](#output\_public\_subnet\_cidr\_blocks) | List of public subnet CIDR blocks |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | List of public subnet IDs |
| <a name="output_public_subnet_regions"></a> [public\_subnet\_regions](#output\_public\_subnet\_regions) | List of public subnet regions |
| <a name="output_public_subnet_self_links"></a> [public\_subnet\_self\_links](#output\_public\_subnet\_self\_links) | List of public subnet self links |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | The URI of the created resource |
<!-- END_TF_DOCS -->
