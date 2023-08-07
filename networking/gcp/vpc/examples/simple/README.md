# GCP VPC

To create a simple GCP VPC:

```bash
terraform init
terraform plan
terraform apply
```

To delete all resource:

```bash
terraform destroy
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 4.75.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.5.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_simple_vpc"></a> [simple\_vpc](#module\_simple\_vpc) | ../../../vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | The GCP region used to deploy NAT routers if used | `string` | `"europe-west9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The VPC |
| <a name="output_name"></a> [name](#output\_name) | The name of the VPC |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | Map of private subnets |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | Map of public subnets |
<!-- END_TF_DOCS -->