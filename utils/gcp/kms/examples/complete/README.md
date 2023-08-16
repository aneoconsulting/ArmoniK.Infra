# AWS ECR

To create an AWS ECR :

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
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.75.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_complete_kms_example"></a> [complete\_kms\_example](#module\_complete\_kms\_example) | ../../../kms | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | The GCP region used to deploy NAT routers if used | `string` | `"europe-west9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_crypto_key"></a> [crypto\_key](#output\_crypto\_key) | The generated crytpo key. |
| <a name="output_kms_crypto_roles"></a> [kms\_crypto\_roles](#output\_kms\_crypto\_roles) | The associated roles on the crytpo key. |
| <a name="output_kms_key_ring"></a> [kms\_key\_ring](#output\_kms\_key\_ring) | The generated key ring. |
| <a name="output_kms_key_ring_import_job"></a> [kms\_key\_ring\_import\_job](#output\_kms\_key\_ring\_import\_job) | The import generated import job. |
| <a name="output_kms_ring_roles"></a> [kms\_ring\_roles](#output\_kms\_ring\_roles) | The associated roles on the key ring. |
<!-- END_TF_DOCS -->
