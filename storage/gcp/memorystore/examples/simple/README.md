# GCP Memorystore

To create a simple GCP Memorystore:

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
| <a name="module_simple_memorystore"></a> [simple\_memorystore](#module\_simple\_memorystore) | ../../../memorystore | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"armonik-gcp-13469"` | no |
| <a name="input_region"></a> [region](#input\_region) | The GCP region to deploy the subnets in | `string` | `"europe-west9"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_auth_string"></a> [auth\_string](#output\_auth\_string) | AUTH String set on the instance. This field will only be populated if auth\_enabled is true. |
| <a name="output_current_location_id"></a> [current\_location\_id](#output\_current\_location\_id) | The current zone where the Redis endpoint is placed. |
| <a name="output_host"></a> [host](#output\_host) | The IP address of the instance. |
| <a name="output_id"></a> [id](#output\_id) | The memorystore instance ID. |
| <a name="output_persistence_iam_identity"></a> [persistence\_iam\_identity](#output\_persistence\_iam\_identity) | Cloud IAM identity used by import/export operations. Format is 'serviceAccount:'. May change over time |
| <a name="output_port"></a> [port](#output\_port) | The port number of the exposed Redis endpoint. |
| <a name="output_read_endpoint"></a> [read\_endpoint](#output\_read\_endpoint) | The IP address of the exposed readonly Redis endpoint. |
| <a name="output_region"></a> [region](#output\_region) | The region the instance lives in. |
| <a name="output_server_ca_certs"></a> [server\_ca\_certs](#output\_server\_ca\_certs) | List of server CA certificates for the instance |
<!-- END_TF_DOCS -->