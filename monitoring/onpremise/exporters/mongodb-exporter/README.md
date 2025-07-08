<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.21.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_deployment.mongodb_exporter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_service.mongodb_exporter_service](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certif_mount"></a> [certif\_mount](#input\_certif\_mount) | MongoDB certificate mount secret | <pre>map(object({<br/>    secret = string<br/>    path   = string<br/>    mode   = string<br/>  }))</pre> | n/a | yes |
| <a name="input_docker_image"></a> [docker\_image](#input\_docker\_image) | Docker image for MongoDB metrics exporter | <pre>object({<br/>    image              = string<br/>    tag                = string<br/>    image_pull_secrets = string<br/>  })</pre> | n/a | yes |
| <a name="input_mongo_url"></a> [mongo\_url](#input\_mongo\_url) | Full MongoDB URI with credentials and tls options included | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace to use for this resource | `string` | n/a | yes |
| <a name="input_should_split_cluster"></a> [should\_split\_cluster](#input\_should\_split\_cluster) | Use this when working with mongodb+srv URIs (this is typically the case with Atlas-managed MongoDB), it adds the '--split-cluster' flag to the exporter flags | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_namespace"></a> [namespace](#output\_namespace) | Namespace of the MongoDB metrics exporter |
| <a name="output_url"></a> [url](#output\_url) | Url of the MongoDB Metrics exporter |
<!-- END_TF_DOCS -->