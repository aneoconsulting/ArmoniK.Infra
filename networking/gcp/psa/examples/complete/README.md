<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.75.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 4.75.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_complete_example"></a> [complete\_example](#module\_complete\_example) | ../../../psa | n/a |

## Resources

| Name | Type |
|------|------|
| [google_compute_network.vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The GCP region to deploy the Artifact registry | `string` | `"europe-west1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_ip_alloc"></a> [private\_ip\_alloc](#output\_private\_ip\_alloc) | The IP address reserved for the VPC |
| <a name="output_private_service_access"></a> [private\_service\_access](#output\_private\_service\_access) | The PSA |
<!-- END_TF_DOCS -->