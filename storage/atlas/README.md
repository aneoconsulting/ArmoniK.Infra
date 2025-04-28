<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |
| <a name="requirement_mongodbatlas"></a> [mongodbatlas](#requirement\_mongodbatlas) | ~> 1.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.21.1 |
| <a name="provider_mongodbatlas"></a> [mongodbatlas](#provider\_mongodbatlas) | ~> 1.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_internet_gateway.ig](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route.route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_security_group.sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.subnet_a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.subnet_b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.vpce](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [kubernetes_secret.mongodb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodb_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodbatlas_connection_string](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [mongodbatlas_database_user.admin](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/database_user) | resource |
| [mongodbatlas_privatelink_endpoint.pe](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/privatelink_endpoint) | resource |
| [mongodbatlas_privatelink_endpoint_service.pe_service](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/privatelink_endpoint_service) | resource |
| [random_password.mongodb_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.mongodb_admin_user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [mongodbatlas_advanced_cluster.akaws](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/data-sources/advanced_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Atlas cluster name | `string` | `"aws-private-connection"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for secrets. | `string` | n/a | yes |
| <a name="input_private_key"></a> [private\_key](#input\_private\_key) | The private API key for MongoDB Atlas | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Atlas project ID | `string` | n/a | yes |
| <a name="input_public_key"></a> [public\_key](#input\_public\_key) | The public API key for MongoDB Atlas | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the private endpoint. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_connection_string"></a> [connection\_string](#output\_connection\_string) | MongoDB Atlas connection string using the private endpoint. |
<!-- END_TF_DOCS -->
