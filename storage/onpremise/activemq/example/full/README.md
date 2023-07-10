<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.21.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.21.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_activemq"></a> [activemq](#module\_activemq) | ../../../activemq | n/a |

## Resources

| Name | Type |
|------|------|
| [kubernetes_namespace.armonik](https://registry.terraform.io/providers/hashicorp/kubernetes/2.21.1/docs/resources/namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_active_deadline_seconds"></a> [active\_deadline\_seconds](#input\_active\_deadline\_seconds) | Optional duration in seconds the pod may be active on the node relative to StartTime before the system will actively try to mark it failed and kill associated containers. Value must be a positive integer | `number` | `null` | no |
| <a name="input_image"></a> [image](#input\_image) | images of services | `string` | n/a | yes |
| <a name="input_image_pull_secrets"></a> [image\_pull\_secrets](#input\_image\_pull\_secrets) | (Optional) Specify list of pull secrets | `map(string)` | n/a | yes |
| <a name="input_kub_config_context"></a> [kub\_config\_context](#input\_kub\_config\_context) | value | `string` | n/a | yes |
| <a name="input_kub_config_path"></a> [kub\_config\_path](#input\_kub\_config\_path) | value | `string` | n/a | yes |
| <a name="input_min_ready_seconds"></a> [min\_ready\_seconds](#input\_min\_ready\_seconds) | Field that specifies the minimum number of seconds for which a newly created Pod should be ready without any of its containers crashing, for it to be considered available | `number` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | value | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK storage resources | `string` | n/a | yes |
| <a name="input_node_name"></a> [node\_name](#input\_node\_name) | value | `string` | `""` | no |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Specify node selector for pod | `map(string)` | `{}` | no |
| <a name="input_priority_class_name"></a> [priority\_class\_name](#input\_priority\_class\_name) | value | `string` | `""` | no |
| <a name="input_progress_deadline_seconds"></a> [progress\_deadline\_seconds](#input\_progress\_deadline\_seconds) | The maximum time in seconds for a deployment to make progress before it is considered to be failed | `number` | `600` | no |
| <a name="input_restart_policy"></a> [restart\_policy](#input\_restart\_policy) | Restart policy for all containers within the pod. One of Always, OnFailure, Never | `string` | `"Always"` | no |
| <a name="input_revision_history_limit"></a> [revision\_history\_limit](#input\_revision\_history\_limit) | The number of revision hitory to keep. | `number` | `10` | no |
| <a name="input_rolling_update"></a> [rolling\_update](#input\_rolling\_update) | Rolling update config params. Present only if strategy\_update = RollingUpdate | `object({ max_surge = optional(string), max_unavailable = optional(string) })` | `{}` | no |
| <a name="input_security_context"></a> [security\_context](#input\_security\_context) | (Optional) SecurityContext holds pod-level security attributes and common container settings | `list(any)` | `[]` | no |
| <a name="input_strategy_update"></a> [strategy\_update](#input\_strategy\_update) | Rolling update config params. Present only if strategy\_update = RollingUpdate | `string` | `null` | no |
| <a name="input_tag"></a> [tag](#input\_tag) | tag of images | `string` | n/a | yes |
| <a name="input_termination_grace_period_seconds"></a> [termination\_grace\_period\_seconds](#input\_termination\_grace\_period\_seconds) | Duration in seconds the pod needs to terminate gracefully | `number` | `null` | no |
| <a name="input_toleration"></a> [toleration](#input\_toleration) | (Optional) Pod node tolerations | <pre>list(object({<br>    effect             = optional(string)<br>    key                = optional(string)<br>    operator           = optional(string)<br>    toleration_seconds = optional(string)<br>    value              = optional(string)<br>  }))</pre> | `[]` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->