# MongoDB Atlas AWS PrivateLink Terraform Module

This module creates a MongoDB Atlas cluster with AWS PrivateLink integration.

## Usage

```hcl
module "atlas" {
  source              = "../atlas"
  atlas_public_key    = "<ATLAS_PUBLIC_KEY>"
  atlas_private_key   = "<ATLAS_PRIVATE_KEY>"
  atlas_org_id        = "<ATLAS_ORG_ID>"
  project_name        = "my-project"
  cluster_name        = "my-cluster"
  atlas_region        = "EU_WEST_1"
  instance_size       = "M10"
  aws_region          = "eu-west-1"
  aws_profile         = "default"
  vpc_id              = "<VPC_ID>"
  subnet_ids          = ["<SUBNET_ID1>", "<SUBNET_ID2>"]
  security_group_ids  = ["<SG_ID>"]
}
```

## Outputs

- `private_connection_string`: Private SRV connection string for the Atlas cluster
- `atlas_project_id`: Atlas project ID
- `atlas_cluster_id`: Atlas cluster ID
- `aws_vpc_endpoint_id`: AWS VPC endpoint ID

---

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |
| <a name="requirement_mongodbatlas"></a> [mongodbatlas](#requirement\_mongodbatlas) | >= 1.10.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.21.1 |
| <a name="provider_mongodbatlas"></a> [mongodbatlas](#provider\_mongodbatlas) | >= 1.10.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.1 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.5.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_vpc_endpoint.mongodb_atlas](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [kubernetes_secret.mongodb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodb_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodbatlas_connection_string](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [mongodbatlas_database_user.admin](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/database_user) | resource |
| [mongodbatlas_privatelink_endpoint.pe](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/privatelink_endpoint) | resource |
| [mongodbatlas_privatelink_endpoint_service.pe_service](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/privatelink_endpoint_service) | resource |
| [null_resource.wait_for_privatelink](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.mongodb_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.mongodb_admin_user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [mongodbatlas_advanced_cluster.akaws](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/data-sources/advanced_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_atlas"></a> [atlas](#input\_atlas) | Atlas project parameters | <pre>object({<br/>    cluster_name = string<br/>    project_id   = string<br/>  })</pre> | n/a | yes |
| <a name="input_endpoint_id"></a> [endpoint\_id](#input\_endpoint\_id) | Existing VPC Endpoint ID for MongoDB Atlas PrivateLink (starting with vpce-) | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for secrets. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for the private endpoint. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID to use for creating a VPC endpoint for MongoDB Atlas | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_atlas_outputs"></a> [atlas\_outputs](#output\_atlas\_outputs) | Atlas configuration outputs for ArmoniK |
| <a name="output_config"></a> [config](#output\_config) | MongoDB configuration for ArmoniK |
| <a name="output_connection_string"></a> [connection\_string](#output\_connection\_string) | MongoDB Atlas connection string |
| <a name="output_endpoint_service_name"></a> [endpoint\_service\_name](#output\_endpoint\_service\_name) | MongoDB Atlas privatelink endpoint service name |
| <a name="output_mongodb_url"></a> [mongodb\_url](#output\_mongodb\_url) | MongoDB URL information |
<!-- END_TF_DOCS -->