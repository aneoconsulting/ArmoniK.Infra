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
| [google_compute_router.router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.nat_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_compute_subnetwork.pod_subnets](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.private_subnets](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.public_subnets](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_external_access"></a> [enable\_external\_access](#input\_enable\_external\_access) | Boolean to disable external access | `bool` | `true` | no |
| <a name="input_enable_google_access"></a> [enable\_google\_access](#input\_enable\_google\_access) | Enable the access to Google APIs to VMs without public IP | `bool` | `true` | no |
| <a name="input_flow_log_max_aggregation_interval"></a> [flow\_log\_max\_aggregation\_interval](#input\_flow\_log\_max\_aggregation\_interval) | The maximum interval of time during which a flow of packets is captured and aggregated into a flow log | `string` | `"INTERVAL_1_MIN"` | no |
| <a name="input_gke_name"></a> [gke\_name](#input\_gke\_name) | Name of the GKE to be deployed in this VPC | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the VPC | `string` | `"armonik-vpc"` | no |
| <a name="input_pod_subnets"></a> [pod\_subnets](#input\_pod\_subnets) | List of CIDR blocks for Pods | `list(string)` | `[]` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | A list of private subnets inside the VPC | `list(string)` | `[]` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A list of public subnets inside the VPC | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where to deploy the different subnets | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_enable_external_access"></a> [enable\_external\_access](#output\_enable\_external\_access) | Boolean to disable external access |
| <a name="output_id"></a> [id](#output\_id) | The VPC |
| <a name="output_name"></a> [name](#output\_name) | The name of the VPC |
| <a name="output_pod_subnets"></a> [pod\_subnets](#output\_pod\_subnets) | List of Pods subnets |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of private subnets |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List  of public subnets |
| <a name="output_region"></a> [region](#output\_region) | Region used for the subnets |
<!-- END_TF_DOCS -->
