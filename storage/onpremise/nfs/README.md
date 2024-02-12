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
| [kubernetes_cluster_role.nfs-client-provisioner-runner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role) | resource |
| [kubernetes_cluster_role_binding.run-nfs-client-provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_deployment.nfs-provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment) | resource |
| [kubernetes_persistent_volume_claim.nfs_claim](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume_claim) | resource |
| [kubernetes_role.leader-locking-nfs-client-provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) | resource |
| [kubernetes_role_binding.leader-locking-nfs-client-provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [kubernetes_service_account.nfs-client-provisioner](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_storage_class.nfs_client](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK storage resources | `string` | n/a | yes |
| <a name="input_nfs_client"></a> [nfs\_client](#input\_nfs\_client) | Parameters of nfs\_client | <pre>object({<br>    image              = string<br>    tag                = string<br>    node_selector      = any<br>    image_pull_secrets = string<br>    max_memory         = string<br>  })</pre> | <pre>{<br>  "image": "k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner",<br>  "image_pull_secrets": "",<br>  "max_memory": "",<br>  "node_selector": {},<br>  "tag": "v4.0.2"<br>}</pre> | no |
| <a name="input_nfs_path"></a> [nfs\_path](#input\_nfs\_path) | path on server | `string` | n/a | yes |
| <a name="input_nfs_server"></a> [nfs\_server](#input\_nfs\_server) | ip nfs server | `string` | n/a | yes |
| <a name="input_pvc_name"></a> [pvc\_name](#input\_pvc\_name) | Name for the pvc to be created and used | `string` | `"nfsvolume"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_provisioner_name"></a> [provisioner\_name](#output\_provisioner\_name) | n/a |