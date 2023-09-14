# Service IP

This module helps to retrieve the domain, IP, and ports of a Kubernetes service.

If `service` ends up being `null`, all the outputs of the module will be null as well.

If `service` is an headless service, the `ip` output will be null. You can use the `host` output to have the IP of the service if it exists, or the domain name of the service otherwise.
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_domain"></a> [cluster\_domain](#input\_cluster\_domain) | Internal domain name of the Kubernetes cluster | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | Service object | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_domain"></a> [domain](#output\_domain) | Domain Name of the service |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | Fully Qualified Domain Name (FQDN) of the service |
| <a name="output_host"></a> [host](#output\_host) | Either the IP or the FQDN of the service |
| <a name="output_ip"></a> [ip](#output\_ip) | IP of the service |
| <a name="output_ports"></a> [ports](#output\_ports) | Ports of the service |
<!-- END_TF_DOCS -->
