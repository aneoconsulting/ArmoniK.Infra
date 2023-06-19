# OnPremise kubeadm

Create an kubernetes cluster

* Red Hat or CentOs only
* CNI : Calico or Flannel
* Load balancer : MetalLB
* VMs must already exists
* VMs DNS/IP must be reachable
* Need SSH access

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [null_resource.install_kubernetes_cluster_node_masters](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.install_kubernetes_cluster_node_worker](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cni_pluggin"></a> [cni\_pluggin](#input\_cni\_pluggin) | The cni plugin to be used. calico or flannel | `string` | `"calico"` | no |
| <a name="input_cni_pluggin_cidr"></a> [cni\_pluggin\_cidr](#input\_cni\_pluggin\_cidr) | The cidr of cni pluggin used by kubeadm configuration on master | `string` | `null` | no |
| <a name="input_kubeadm_token"></a> [kubeadm\_token](#input\_kubeadm\_token) | The generated kubeadm token used by worker node to join the master | `string` | n/a | yes |
| <a name="input_loadbalancer_plugin"></a> [loadbalancer\_plugin](#input\_loadbalancer\_plugin) | loadbalancer plugin to be used. Only metalLB or no Loadbalancer for now | `string` | `""` | no |
| <a name="input_master_node_name"></a> [master\_node\_name](#input\_master\_node\_name) | The name of the cluster master node. | `string` | `"master"` | no |
| <a name="input_master_private_ip"></a> [master\_private\_ip](#input\_master\_private\_ip) | The private ip of the master node. | `string` | n/a | yes |
| <a name="input_master_public_ip"></a> [master\_public\_ip](#input\_master\_public\_ip) | The public ip of the master node. | `string` | n/a | yes |
| <a name="input_tls_private_key_pem"></a> [tls\_private\_key\_pem](#input\_tls\_private\_key\_pem) | The private key of the master node. | `string` | n/a | yes |
| <a name="input_user"></a> [user](#input\_user) | user used to execute docker + kubernetes scripts. must be updated accordingly with the linux image used | `string` | n/a | yes |
| <a name="input_workers"></a> [workers](#input\_workers) | The worker nodes to be deployed. | <pre>map(object({<br>    instance_count = optional(number, 1)<br>    label          = optional(list(string), [])<br>    name           = string<br>    public_dns     = string<br>    taints         = optional(list(string), [])<br>  }))</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
