## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.7.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.7.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_cluster_role.nfs_client_provisioner_runner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.run_nfs_client_provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_deployment.nfs_provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_persistent_volume_claim.nfs_claim](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_role.leader_locking_nfs_client_provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) | resource |
| [kubernetes_role_binding.leader_locking_nfs_client_provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [kubernetes_service_account.nfs_client_provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_storage_class.nfs_client](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_image"></a> [image](#input\_image) | image for the external client provisioner | `string` | `"k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner"` | no |
| <a name="input_image_policy"></a> [image\_policy](#input\_image\_policy) | policy  for getting the image | `string` | `"IfNotPresent"` | no |
| <a name="input_image_pull_secrets"></a> [image\_pull\_secrets](#input\_image\_pull\_secrets) | pull secrets if needed | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK storage resources | `string` | n/a | yes |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | selectors | `any` | `{}` | no |
| <a name="input_path"></a> [path](#input\_path) | path on server | `string` | n/a | yes |
| <a name="input_pvc_name"></a> [pvc\_name](#input\_pvc\_name) | Name for the pvc to be created and used | `string` | `"nfsvolume"` | no |
| <a name="input_server"></a> [server](#input\_server) | ip nfs server | `string` | n/a | yes |
| <a name="input_tag"></a> [tag](#input\_tag) | tag for the image | `string` | `"v4.0.2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_provisioner_name"></a> [provisioner\_name](#output\_provisioner\_name) | name of the created provisionner |
| <a name="output_pvc_name"></a> [pvc\_name](#output\_pvc\_name) | name of the created persistant volume claim |
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.7.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.7.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [kubernetes_cluster_role.nfs_client_provisioner_runner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.run_nfs_client_provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_deployment.nfs_provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_persistent_volume_claim.nfs_claim](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_role.leader_locking_nfs_client_provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) | resource |
| [kubernetes_role_binding.leader_locking_nfs_client_provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [kubernetes_service_account.nfs_client_provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_storage_class.nfs_client](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_image"></a> [image](#input\_image) | image for the external client provisioner | `string` | `"k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner"` | no |
| <a name="input_image_policy"></a> [image\_policy](#input\_image\_policy) | policy  for getting the image | `string` | `"IfNotPresent"` | no |
| <a name="input_image_pull_secrets"></a> [image\_pull\_secrets](#input\_image\_pull\_secrets) | pull secrets if needed | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK storage resources | `string` | n/a | yes |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | selectors | `any` | `{}` | no |
| <a name="input_path"></a> [path](#input\_path) | path on server | `string` | n/a | yes |
| <a name="input_pvc_name"></a> [pvc\_name](#input\_pvc\_name) | Name for the pvc to be created and used | `string` | `"nfsvolume"` | no |
| <a name="input_server"></a> [server](#input\_server) | ip nfs server | `string` | n/a | yes |
| <a name="input_size"></a> [size](#input\_size) | storage request size | `string` | `"5Gi"` | no |
| <a name="input_tag"></a> [tag](#input\_tag) | tag for the image | `string` | `"v4.0.2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_provisioner_name"></a> [provisioner\_name](#output\_provisioner\_name) | name of the created provisionner |
| <a name="output_pvc_name"></a> [pvc\_name](#output\_pvc\_name) | name of the created persistant volume claim |
<!-- END_TF_DOCS -->