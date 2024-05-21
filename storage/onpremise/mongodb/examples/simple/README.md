# MongoDB instance

To create a simple MongoDB instance on your local machine:

```bash
terraform init
terraform plan
terraform apply
```

To delete all resource:

```bash
terraform destroy
```


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_simple_mongodb_instance"></a> [simple\_mongodb\_instance](#module\_simple\_mongodb\_instance) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kube_config_path"></a> [kube\_config\_path](#input\_kube\_config\_path) | The kubernetes configuration file path you want to specify | `string` | `"~/.kube/config"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of ArmoniK resources | `string` | `"default"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Endpoints of MongoDB |
| <a name="output_host"></a> [host](#output\_host) | Hostname or IP address of MongoDB server |
| <a name="output_number_of_replicas"></a> [number\_of\_replicas](#output\_number\_of\_replicas) | Number of replicas of MongoDB |
| <a name="output_port"></a> [port](#output\_port) | Port of MongoDB server |
| <a name="output_url"></a> [url](#output\_url) | URL of MongoDB server |
| <a name="output_user_credentials"></a> [user\_credentials](#output\_user\_credentials) | User credentials of MongoDB |
<!-- END_TF_DOCS -->
