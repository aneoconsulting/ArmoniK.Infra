<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.3.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.10.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.3.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.10.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.21.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | >= 4.0.4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_efs"></a> [efs](#module\_efs) | ../../../storage/aws/efs | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.eks_oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.efs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.efs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.efs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.efs_csi](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_service_account.efs_csi_driver](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [aws_iam_policy_document.efs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [tls_certificate.eks](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_csi_driver"></a> [csi\_driver](#input\_csi\_driver) | EFS CSI info | <pre>object({<br>    name               = string<br>    namespace          = string<br>    image_pull_secrets = string<br>    node_selector      = any<br>    repository         = string<br>    version            = string<br>    docker_images = object({<br>      efs_csi = object({<br>        image = string<br>        tag   = string<br>      })<br>      livenessprobe = object({<br>        image = string<br>        tag   = string<br>      })<br>      node_driver_registrar = object({<br>        image = string<br>        tag   = string<br>      })<br>      external_provisioner = object({<br>        image = string<br>        tag   = string<br>      })<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_efs"></a> [efs](#input\_efs) | Info about the EFS | <pre>object({<br>    name                            = string<br>    kms_key_id                      = string<br>    performance_mode                = string<br>    throughput_mode                 = string<br>    provisioned_throughput_in_mibps = number<br>    transition_to_ia                = string<br>    access_point                    = list(string)<br>  })</pre> | n/a | yes |
| <a name="input_eks_issuer"></a> [eks\_issuer](#input\_eks\_issuer) | EKS issuer | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for EFS CSI driver | `map(string)` | n/a | yes |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | AWS VPC info | <pre>object({<br>    id                 = string<br>    cidr_block_private = set(string)<br>    cidr_blocks        = set(string)<br>    subnet_ids         = set(string)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_efs_id"></a> [efs\_id](#output\_efs\_id) | EFS id for the persistent volume |
<!-- END_TF_DOCS -->
