<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.5.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_install_kubeadm_cluster"></a> [install\_kubeadm\_cluster](#module\_install\_kubeadm\_cluster) | ../.. | n/a |

## Resources

| Name | Type |
|------|------|
| [null_resource.download_kubeconfig_file](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_string.token_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.token_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubeconfig_file"></a> [kubeconfig\_file](#output\_kubeconfig\_file) | A sample command to display nodes of your cluster |
<!-- END_TF_DOCS -->