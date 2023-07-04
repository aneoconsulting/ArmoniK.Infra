<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.1 |
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
| <a name="output_display_nodes_command_jelp"></a> [display\_nodes\_command\_jelp](#output\_display\_nodes\_command\_jelp) | A sample command to display nodes of your cluster |
| <a name="output_kubeconfig_file_export_help"></a> [kubeconfig\_file\_export\_help](#output\_kubeconfig\_file\_export\_help) | Use this export to begin to use your cluster |
<!-- END_TF_DOCS -->