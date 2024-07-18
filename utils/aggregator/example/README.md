<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.31.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.31.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_activemq"></a> [activemq](#module\_activemq) | ../../../storage/onpremise/activemq | n/a |
| <a name="module_control_plane"></a> [control\_plane](#module\_control\_plane) | ../../aggregator | n/a |
| <a name="module_redis"></a> [redis](#module\_redis) | ../../../storage/onpremise/redis | n/a |

## Resources

| Name | Type |
|------|------|
| [kubernetes_deployment.example](https://registry.terraform.io/providers/hashicorp/kubernetes/2.31.0/docs/resources/deployment) | resource |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->