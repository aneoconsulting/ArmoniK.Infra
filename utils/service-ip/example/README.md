# Kubernetes service

To create a Kubernetes service and get its domain, IP, and port:

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
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.7.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.7.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_my_svc_ip"></a> [my\_svc\_ip](#module\_my\_svc\_ip) | ./.. | n/a |

## Resources

| Name | Type |
|------|------|
| [kubernetes_service.my_svc](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |
| [kubernetes_config_map.dns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/config_map) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where to deploy the service | `string` | `"default"` | no |
| <a name="input_port"></a> [port](#input\_port) | Port on which to expose the service | `number` | n/a | yes |
| <a name="input_type"></a> [type](#input\_type) | Type of service to deploy | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_domain"></a> [domain](#output\_domain) | Domain of the service deployed |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | Fully Qualified Domain Name of the service deployed |
| <a name="output_host"></a> [host](#output\_host) | Either the IP of the FQDN or the deployed service |
| <a name="output_ip"></a> [ip](#output\_ip) | IP of the service deployed |
| <a name="output_port"></a> [port](#output\_port) | Port used by the service deployed |
<!-- END_TF_DOCS -->