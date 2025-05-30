# Onpremise Kubeadm

The Terraform scripts use the module [kubeadm](../../kubeadm) to install and configure a Kubernetes cluster with `Kubeadm`.

First, you should have a list of barre metal ou virtual machines, and then you have to update values `PUBLIC_DNS_HERE`
, `PRIVATE_DNS_HERE` and `TLS_PRIVATE_KEY_FILE_HERE` in the file [terraform.tfvars](terraform.tfvars).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.2.1 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.5.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_install_kubeadm_cluster"></a> [install\_kubeadm\_cluster](#module\_install\_kubeadm\_cluster) | ../../../kubeadm | n/a |

## Resources

| Name | Type |
|------|------|
| [null_resource.download_kubeconfig_file](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_string.token_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [random_string.token_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_master"></a> [master](#input\_master) | The master node to be deployed. | <pre>object({<br/>    name                     = string<br/>    public_dns               = string # it can be private if you are inside the destination network<br/>    private_dns              = string<br/>    tls_private_key_pem_file = string<br/>  })</pre> | n/a | yes |
| <a name="input_user"></a> [user](#input\_user) | user used to execute docker + kubernetes scripts. must be updated accordingly with the linux image used | `string` | n/a | yes |
| <a name="input_workers"></a> [workers](#input\_workers) | The worker nodes to be deployed. | <pre>map(object({<br/>    instance_count = optional(number, 1)<br/>    label          = optional(list(string), [])<br/>    name           = string<br/>    public_dns     = string<br/>    taints         = optional(list(string), [])<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_display_nodes_command_help"></a> [display\_nodes\_command\_help](#output\_display\_nodes\_command\_help) | A sample command to display nodes of your cluster |
| <a name="output_kubeconfig_file_export_help"></a> [kubeconfig\_file\_export\_help](#output\_kubeconfig\_file\_export\_help) | Use this export to begin to use your cluster |
<!-- END_TF_DOCS -->