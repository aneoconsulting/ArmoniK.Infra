# MongoDB Atlas GCP Private Service Connect Terraform Module

This module creates a MongoDB Atlas cluster with GCP Private Service Connect integration.

## Prerequisites

- Google Cloud credentials configured (via gcloud CLI, service account, or environment variables)
- VPC network with private subnets
- Firewall rules allowing MongoDB Atlas traffic
- MongoDB Atlas account with organization access
- Atlas project created
- Atlas cluster deployed and configured
- Atlas API keys with PrivateLink permissions

## Usage

```hcl
module "atlas_gcp" {
  source         = "../atlas-gcp"
  project_id     = "<ATLAS_PROJECT_ID>"
  cluster_name   = "my-cluster"
  region         = "us-central1"
  namespace      = "armonik"
  network_id     = "projects/my-project/global/networks/my-vpc"
  subnetwork_id  = "projects/my-project/regions/us-central1/subnetworks/my-subnet"
  ip_address     = null  # Optional: specify IP or let GCP assign automatically
  
  tags = {
    Environment = "production"
    Project     = "armonik"
  }
}
```

## Important Notes

1. **Region Consistency**: Ensure the region specified matches your Atlas cluster's region
2. **Cluster Dependencies**: The Atlas cluster must exist before running this module
3. **Network Requirements**: VPC and subnets must allow traffic to MongoDB Atlas
4. **IP Address**: If not specified, GCP will automatically assign an IP from the subnet

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.75.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |
| <a name="requirement_mongodbatlas"></a> [mongodbatlas](#requirement\_mongodbatlas) | >= 1.12.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 4.75.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.21.1 |
| <a name="provider_mongodbatlas"></a> [mongodbatlas](#provider\_mongodbatlas) | >= 1.12.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_forwarding_rule.mongodb_atlas](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) | resource |
| [kubernetes_secret.mongodb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodb_admin](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.mongodbatlas_connection_string](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [mongodbatlas_database_user.admin](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/database_user) | resource |
| [mongodbatlas_privatelink_endpoint.pe](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/privatelink_endpoint) | resource |
| [mongodbatlas_privatelink_endpoint_service.pe_service](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/privatelink_endpoint_service) | resource |
| [random_password.mongodb_admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.mongodb_admin_user](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [mongodbatlas_advanced_cluster.atlas](https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/data-sources/advanced_cluster) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the MongoDB Atlas cluster | `string` | n/a | yes |
| <a name="input_gcp_project_id"></a> [gcp\_project\_id](#input\_gcp\_project\_id) | The GCP project ID where resources will be created. If not provided, uses the default project from the provider. | `string` | `null` | no |
| <a name="input_ip_address"></a> [ip\_address](#input\_ip\_address) | Optional static IP address for the forwarding rule | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Kubernetes namespace for secrets. | `string` | n/a | yes |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | The ID of the GCP network to use for Private Service Connect | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | ID of the MongoDB Atlas project | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for the private endpoint. | `string` | n/a | yes |
| <a name="input_subnetwork_id"></a> [subnetwork\_id](#input\_subnetwork\_id) | The ID of the GCP subnetwork to use for Private Service Connect | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_connection_string"></a> [connection\_string](#output\_connection\_string) | MongoDB Atlas connection string |
| <a name="output_endpoint_service_name"></a> [endpoint\_service\_name](#output\_endpoint\_service\_name) | MongoDB Atlas privatelink endpoint service name |
| <a name="output_env"></a> [env](#output\_env) | MongoDB Atlas env |
| <a name="output_env_from_secret"></a> [env\_from\_secret](#output\_env\_from\_secret) | MongoDB Atlas env from secret |
| <a name="output_mongodb_url"></a> [mongodb\_url](#output\_mongodb\_url) | MongoDB URL information |
<!-- END_TF_DOCS -->
