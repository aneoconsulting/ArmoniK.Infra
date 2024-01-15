<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.3.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.10.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.13.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.3.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.10.1 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.13.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.1 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_node_termination_handler_role"></a> [aws\_node\_termination\_handler\_role](#module\_aws\_node\_termination\_handler\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 4.1.0 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 19.10.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group_tag.autoscaling_group_tag](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group_tag) | resource |
| [aws_autoscaling_lifecycle_hook.aws_node_termination_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_lifecycle_hook) | resource |
| [aws_cloudwatch_event_rule.aws_node_termination_handler_asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_rule.aws_node_termination_handler_spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_iam_policy.aws_node_termination_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.efs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.worker_autoscaling](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.workers_autoscaling](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.efs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.efs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.aws_node_termination_handler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.efs_csi](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.eni_config](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_service_account.efs_csi_driver_controller](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_service_account.efs_csi_driver_node](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [null_resource.change_cni_label](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.patch_coredns](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.trigger_custom_cni](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.update_kubeconfig](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_string.random_resources](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_autoscaling_groups.groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/autoscaling_groups) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.aws_node_termination_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.efs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.worker_autoscaling](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_chart_name"></a> [chart\_name](#input\_chart\_name) | Name for chart | `string` | `"eniconfig"` | no |
| <a name="input_chart_namespace"></a> [chart\_namespace](#input\_chart\_namespace) | Version for chart | `string` | `"default"` | no |
| <a name="input_chart_repository"></a> [chart\_repository](#input\_chart\_repository) | Path to the charts repository | `string` | `"../../../charts"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | Version for chart | `string` | `"0.1.0"` | no |
| <a name="input_eks"></a> [eks](#input\_eks) | Parameters of AWS EKS | <pre>object({<br>    cluster_version                       = string<br>    cluster_endpoint_private_access       = bool<br>    cluster_endpoint_private_access_cidrs = list(string)<br>    cluster_endpoint_private_access_sg    = list(string)<br>    cluster_endpoint_public_access        = bool<br>    cluster_endpoint_public_access_cidrs  = list(string)<br>    cluster_log_retention_in_days         = number<br>    docker_images = object({<br>      cluster_autoscaler = object({<br>        image = string<br>        tag   = string<br>      })<br>      instance_refresh = object({<br>        image = string<br>        tag   = string<br>      })<br>      efs_csi = object({<br>        image = string<br>        tag   = string<br>      })<br>      livenessprobe = object({<br>        image = string<br>        tag   = string<br>      })<br>      node_driver_registrar = object({<br>        image = string<br>        tag   = string<br>      })<br>      external_provisioner = object({<br>        image = string<br>        tag   = string<br>      })<br>    })<br>    cluster_autoscaler = object({<br>      expander                              = string<br>      scale_down_enabled                    = bool<br>      min_replica_count                     = number<br>      scale_down_utilization_threshold      = number<br>      scale_down_non_empty_candidates_count = number<br>      max_node_provision_time               = string<br>      scan_interval                         = string<br>      scale_down_delay_after_add            = string<br>      scale_down_delay_after_delete         = string<br>      scale_down_delay_after_failure        = string<br>      scale_down_unneeded_time              = string<br>      skip_nodes_with_system_pods           = bool<br>      version                               = string<br>      repository                            = string<br>      namespace                             = string<br>    })<br>    instance_refresh = object({<br>      namespace  = string<br>      repository = string<br>      version    = string<br>    })<br>    efs_csi = object({<br>      name               = string<br>      namespace          = string<br>      image_pull_secrets = string<br>      repository         = string<br>      version            = string<br>    })<br>    encryption_keys = object({<br>      cluster_log_kms_key_id    = string<br>      cluster_encryption_config = string<br>      ebs_kms_key_id            = string<br>    })<br>    map_roles = list(object({<br>      rolearn  = string<br>      username = string<br>      groups   = list(string)<br>    }))<br>    map_users = list(object({<br>      userarn  = string<br>      username = string<br>      groups   = list(string)<br>    }))<br>  })</pre> | n/a | yes |
| <a name="input_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#input\_eks\_managed\_node\_groups) | List of EKS managed node groups | `any` | `null` | no |
| <a name="input_fargate_profiles"></a> [fargate\_profiles](#input\_fargate\_profiles) | List of fargate profiles | `any` | `null` | no |
| <a name="input_kubeconfig_file"></a> [kubeconfig\_file](#input\_kubeconfig\_file) | Kubeconfig file path | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | AWS EKS service name | `string` | `"armonik-eks"` | no |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for pods of EKS system | `any` | `{}` | no |
| <a name="input_profile"></a> [profile](#input\_profile) | Profile of AWS credentials to deploy Terraform sources | `string` | n/a | yes |
| <a name="input_self_managed_node_groups"></a> [self\_managed\_node\_groups](#input\_self\_managed\_node\_groups) | List of self managed node groups | `any` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for resource | `map(string)` | `{}` | no |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | AWS VPC info | <pre>object({<br>    id                 = string<br>    private_subnet_ids = list(string)<br>    pods_subnet_ids    = list(string)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of EKS cluster |
| <a name="output_aws_eks_module"></a> [aws\_eks\_module](#output\_aws\_eks\_module) | aws eks module |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | cluster\_certificate\_authority\_data |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for EKS control plane |
| <a name="output_cluster_iam_role_name"></a> [cluster\_iam\_role\_name](#output\_cluster\_iam\_role\_name) | Cluster IAM role name |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | EKS cluster ID  used for backword compatibility : https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/UPGRADE-19.0.md#list-of-backwards-incompatible-changes |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | EKS cluster name |
| <a name="output_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#output\_eks\_managed\_node\_groups) | List of EKS managed group nodes |
| <a name="output_eks_managed_worker_iam_role_names"></a> [eks\_managed\_worker\_iam\_role\_names](#output\_eks\_managed\_worker\_iam\_role\_names) | list of the EKS managed workers IAM role names |
| <a name="output_fargate_profiles"></a> [fargate\_profiles](#output\_fargate\_profiles) | List of fargate profiles |
| <a name="output_fargate_profiles_worker_iam_role_names"></a> [fargate\_profiles\_worker\_iam\_role\_names](#output\_fargate\_profiles\_worker\_iam\_role\_names) | list of the fargate profile workers IAM role names |
| <a name="output_issuer"></a> [issuer](#output\_issuer) | EKS Identity issuer |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ARN of KMS used for EKS |
| <a name="output_kubeconfig_file"></a> [kubeconfig\_file](#output\_kubeconfig\_file) | Path of kubeconfig file |
| <a name="output_self_managed_node_groups"></a> [self\_managed\_node\_groups](#output\_self\_managed\_node\_groups) | List of self managed node groups |
| <a name="output_self_managed_worker_iam_role_names"></a> [self\_managed\_worker\_iam\_role\_names](#output\_self\_managed\_worker\_iam\_role\_names) | list of the self managed workers IAM role names |
| <a name="output_worker_iam_role_names"></a> [worker\_iam\_role\_names](#output\_worker\_iam\_role\_names) | list of the workers IAM role names |
<!-- END_TF_DOCS -->
