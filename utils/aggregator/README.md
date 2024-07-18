<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_conf_list"></a> [conf\_list](#input\_conf\_list) | List of module output with the config | <pre>list(object({<br>    env           = optional(map(string), {})<br>    env_configmap = optional(set(string), [])<br>    env_from_configmap = optional(map(object({<br>      configmap = string<br>      field     = string<br>    })), {})<br>    env_secret = optional(set(string), [])<br>    env_from_secret = optional(map(object({<br>      secret = string<br>      field  = string<br>    })), {})<br>    mount_configmap = optional(map(object({<br>      configmap = string<br>      path      = string<br>      subpath   = optional(string)<br>      mode      = optional(string, "644")<br>      items = optional(map(object({<br>        field = string<br>        mode  = optional(string)<br>      })))<br>    })), {})<br>    mount_secret = optional(map(object({<br>      secret  = string<br>      path    = string<br>      subpath = optional(string)<br>      mode    = optional(string, "644")<br>      items = optional(map(object({<br>        field = string<br>        mode  = optional(string)<br>      })))<br>    })), {})<br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_env"></a> [env](#output\_env) | Environment variables |
| <a name="output_env_configmap"></a> [env\_configmap](#output\_env\_configmap) | Environment variables as configmaps |
| <a name="output_env_from_configmap"></a> [env\_from\_configmap](#output\_env\_from\_configmap) | Environment variables from configmaps |
| <a name="output_env_from_secret"></a> [env\_from\_secret](#output\_env\_from\_secret) | Environment variable from secrets |
| <a name="output_env_secret"></a> [env\_secret](#output\_env\_secret) | Environment variables as secrets |
| <a name="output_mount_configmap"></a> [mount\_configmap](#output\_mount\_configmap) | configmaps to mount as volume |
| <a name="output_mount_secret"></a> [mount\_secret](#output\_mount\_secret) | Secrets to mount as volume |
<!-- END_TF_DOCS -->