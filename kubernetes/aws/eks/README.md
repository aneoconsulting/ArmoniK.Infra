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
| <a name="module_aws_node_termination_handler_role"></a> [aws\_node\_termination\_handler\_role](#module\_aws\_node\_termination\_handler\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 4.24.1 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 19.21.0 |

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
| <a name="input_cluster_autoscaler_expander"></a> [cluster\_autoscaler\_expander](#input\_cluster\_autoscaler\_expander) | Type of node group expander to be used in scale up. | `string` | `"random"` | no |
| <a name="input_cluster_autoscaler_image"></a> [cluster\_autoscaler\_image](#input\_cluster\_autoscaler\_image) | Image name of the cluster autoscaler | `string` | n/a | yes |
| <a name="input_cluster_autoscaler_max_node_provision_time"></a> [cluster\_autoscaler\_max\_node\_provision\_time](#input\_cluster\_autoscaler\_max\_node\_provision\_time) | Maximum time CA waits for node to be provisioned | `string` | `"15m"` | no |
| <a name="input_cluster_autoscaler_min_replica_count"></a> [cluster\_autoscaler\_min\_replica\_count](#input\_cluster\_autoscaler\_min\_replica\_count) | Minimum number or replicas that a replica set or replication controller should have to allow their pods deletion in scale down | `number` | `0` | no |
| <a name="input_cluster_autoscaler_namespace"></a> [cluster\_autoscaler\_namespace](#input\_cluster\_autoscaler\_namespace) | Cluster autoscaler namespace | `string` | n/a | yes |
| <a name="input_cluster_autoscaler_repository"></a> [cluster\_autoscaler\_repository](#input\_cluster\_autoscaler\_repository) | Path to cluster autoscaler helm chart repository | `string` | n/a | yes |
| <a name="input_cluster_autoscaler_scale_down_delay_after_add"></a> [cluster\_autoscaler\_scale\_down\_delay\_after\_add](#input\_cluster\_autoscaler\_scale\_down\_delay\_after\_add) | How long after scale up that scale down evaluation resumes | `string` | `"10m"` | no |
| <a name="input_cluster_autoscaler_scale_down_delay_after_delete"></a> [cluster\_autoscaler\_scale\_down\_delay\_after\_delete](#input\_cluster\_autoscaler\_scale\_down\_delay\_after\_delete) | How long after node deletion that scale down evaluation resumes, defaults to scan-interval | `string` | n/a | yes |
| <a name="input_cluster_autoscaler_scale_down_delay_after_failure"></a> [cluster\_autoscaler\_scale\_down\_delay\_after\_failure](#input\_cluster\_autoscaler\_scale\_down\_delay\_after\_failure) | How long after scale down failure that scale down evaluation resumes | `string` | `"3m"` | no |
| <a name="input_cluster_autoscaler_scale_down_enabled"></a> [cluster\_autoscaler\_scale\_down\_enabled](#input\_cluster\_autoscaler\_scale\_down\_enabled) | Should CA scale down the cluster | `bool` | `true` | no |
| <a name="input_cluster_autoscaler_scale_down_non_empty_candidates_count"></a> [cluster\_autoscaler\_scale\_down\_non\_empty\_candidates\_count](#input\_cluster\_autoscaler\_scale\_down\_non\_empty\_candidates\_count) | Maximum number of non empty nodes considered in one iteration as candidates for scale down with drain | `number` | `30` | no |
| <a name="input_cluster_autoscaler_scale_down_unneeded_time"></a> [cluster\_autoscaler\_scale\_down\_unneeded\_time](#input\_cluster\_autoscaler\_scale\_down\_unneeded\_time) | How long a node should be unneeded before it is eligible for scale down | `string` | `"10m"` | no |
| <a name="input_cluster_autoscaler_scale_down_utilization_threshold"></a> [cluster\_autoscaler\_scale\_down\_utilization\_threshold](#input\_cluster\_autoscaler\_scale\_down\_utilization\_threshold) | Node utilization level, defined as sum of requested resources divided by capacity, below which a node can be considered for scale down | `number` | `0.5` | no |
| <a name="input_cluster_autoscaler_scan_interval"></a> [cluster\_autoscaler\_scan\_interval](#input\_cluster\_autoscaler\_scan\_interval) | How often cluster is reevaluated for scale up or down | `string` | `"10s"` | no |
| <a name="input_cluster_autoscaler_skip_nodes_with_system_pods"></a> [cluster\_autoscaler\_skip\_nodes\_with\_system\_pods](#input\_cluster\_autoscaler\_skip\_nodes\_with\_system\_pods) | If true cluster autoscaler will never delete nodes with pods from kube-system (except for DaemonSet or mirror pods) | `bool` | `true` | no |
| <a name="input_cluster_autoscaler_tag"></a> [cluster\_autoscaler\_tag](#input\_cluster\_autoscaler\_tag) | Tag of the cluster autoscaler image | `string` | n/a | yes |
| <a name="input_cluster_autoscaler_version"></a> [cluster\_autoscaler\_version](#input\_cluster\_autoscaler\_version) | Cluster autoscaler helm chart version | `string` | n/a | yes |
| <a name="input_cluster_encryption_config"></a> [cluster\_encryption\_config](#input\_cluster\_encryption\_config) | Configuration block with encryption configuration for the cluster. To disable secret encryption, set this value to {} | `string` | n/a | yes |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Indicates whether or not the Amazon EKS private API server endpoint is enabled | `bool` | n/a | yes |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Indicates whether or not the Amazon EKS private API server endpoint is enabled | `bool` | n/a | yes |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS public API server endpoint | `list(string)` | n/a | yes |
| <a name="input_cluster_log_kms_key_id"></a> [cluster\_log\_kms\_key\_id](#input\_cluster\_log\_kms\_key\_id) | KMS id to encrypt/decrypt the cluster's logs | `string` | n/a | yes |
| <a name="input_cluster_log_retention_in_days"></a> [cluster\_log\_retention\_in\_days](#input\_cluster\_log\_retention\_in\_days) | Logs retention in days | `number` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version to use for the EKS cluster | `string` | n/a | yes |
| <a name="input_ebs_kms_key_id"></a> [ebs\_kms\_key\_id](#input\_ebs\_kms\_key\_id) | KMS key id to encrypt/decrypt EBS | `string` | n/a | yes |
| <a name="input_efs_csi_external_provisioner_image"></a> [efs\_csi\_external\_provisioner\_image](#input\_efs\_csi\_external\_provisioner\_image) | EFS CSI external provisioner image name | `string` | n/a | yes |
| <a name="input_efs_csi_external_provisioner_tag"></a> [efs\_csi\_external\_provisioner\_tag](#input\_efs\_csi\_external\_provisioner\_tag) | EFS CSI external provisioner image tag | `string` | n/a | yes |
| <a name="input_efs_csi_image"></a> [efs\_csi\_image](#input\_efs\_csi\_image) | EFS CSI image name | `string` | n/a | yes |
| <a name="input_efs_csi_image_pull_secrets"></a> [efs\_csi\_image\_pull\_secrets](#input\_efs\_csi\_image\_pull\_secrets) | Image pull secret used to pull EFS CSI images | `string` | `null` | no |
| <a name="input_efs_csi_liveness_probe_image"></a> [efs\_csi\_liveness\_probe\_image](#input\_efs\_csi\_liveness\_probe\_image) | EFS CSI liveness probe image name | `string` | n/a | yes |
| <a name="input_efs_csi_liveness_probe_tag"></a> [efs\_csi\_liveness\_probe\_tag](#input\_efs\_csi\_liveness\_probe\_tag) | EFS CSI liveness probe image tag | `string` | n/a | yes |
| <a name="input_efs_csi_name"></a> [efs\_csi\_name](#input\_efs\_csi\_name) | EFS CSI name | `string` | `null` | no |
| <a name="input_efs_csi_namespace"></a> [efs\_csi\_namespace](#input\_efs\_csi\_namespace) | EFS CSI namespace | `string` | `null` | no |
| <a name="input_efs_csi_node_driver_registrar_image"></a> [efs\_csi\_node\_driver\_registrar\_image](#input\_efs\_csi\_node\_driver\_registrar\_image) | EFS CSI node driver registrar image name | `string` | n/a | yes |
| <a name="input_efs_csi_node_driver_registrar_tag"></a> [efs\_csi\_node\_driver\_registrar\_tag](#input\_efs\_csi\_node\_driver\_registrar\_tag) | EFS CSI node driver registrar image tag | `string` | n/a | yes |
| <a name="input_efs_csi_repository"></a> [efs\_csi\_repository](#input\_efs\_csi\_repository) | EFS CSI helm repository | `string` | n/a | yes |
| <a name="input_efs_csi_tag"></a> [efs\_csi\_tag](#input\_efs\_csi\_tag) | EFS CSI image tag | `string` | n/a | yes |
| <a name="input_efs_csi_version"></a> [efs\_csi\_version](#input\_efs\_csi\_version) | EFS CSI helm version | `string` | n/a | yes |
| <a name="input_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#input\_eks\_managed\_node\_groups) | List of EKS managed node groups | `any` | `null` | no |
| <a name="input_fargate_profiles"></a> [fargate\_profiles](#input\_fargate\_profiles) | List of fargate profiles | `any` | `null` | no |
| <a name="input_instance_refresh_image"></a> [instance\_refresh\_image](#input\_instance\_refresh\_image) | Instance refresh image name | `string` | n/a | yes |
| <a name="input_instance_refresh_namespace"></a> [instance\_refresh\_namespace](#input\_instance\_refresh\_namespace) | Instance refresh namespace | `string` | n/a | yes |
| <a name="input_instance_refresh_repository"></a> [instance\_refresh\_repository](#input\_instance\_refresh\_repository) | Path to instance refresh helm chart repository | `string` | n/a | yes |
| <a name="input_instance_refresh_tag"></a> [instance\_refresh\_tag](#input\_instance\_refresh\_tag) | Instance refresh tag | `string` | n/a | yes |
| <a name="input_instance_refresh_version"></a> [instance\_refresh\_version](#input\_instance\_refresh\_version) | Instance refresh helm chart version | `string` | n/a | yes |
| <a name="input_kubeconfig_file"></a> [kubeconfig\_file](#input\_kubeconfig\_file) | Kubeconfig file path | `string` | n/a | yes |
| <a name="input_map_roles_groups"></a> [map\_roles\_groups](#input\_map\_roles\_groups) | List of map roles group | <pre>list(object({<br>    rolearn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | n/a | yes |
| <a name="input_map_users_groups"></a> [map\_users\_groups](#input\_map\_users\_groups) | List of map users group | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | AWS EKS service name | `string` | `"armonik-eks"` | no |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for pods of EKS system | `any` | `{}` | no |
| <a name="input_profile"></a> [profile](#input\_profile) | Profile of AWS credentials to deploy Terraform sources | `string` | n/a | yes |
| <a name="input_self_managed_node_groups"></a> [self\_managed\_node\_groups](#input\_self\_managed\_node\_groups) | List of self managed node groups | `any` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for resource | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | Id of VPC | `string` | n/a | yes |
| <a name="input_vpc_pods_subnet_ids"></a> [vpc\_pods\_subnet\_ids](#input\_vpc\_pods\_subnet\_ids) | List of VPC pods subnet ids | `list(string)` | n/a | yes |
| <a name="input_vpc_private_subnet_ids"></a> [vpc\_private\_subnet\_ids](#input\_vpc\_private\_subnet\_ids) | List of VPC subnets ids | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of EKS cluster |
| <a name="output_aws_eks_module"></a> [aws\_eks\_module](#output\_aws\_eks\_module) | aws eks module |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | cluster\_certificate\_authority\_data |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for EKS control plane |
| <a name="output_cluster_iam_role_name"></a> [cluster\_iam\_role\_name](#output\_cluster\_iam\_role\_name) | Cluster IAM role name |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | EKS cluster ID |
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
