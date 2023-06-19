<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.3.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.3.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecr_repository.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [null_resource.copy_images](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS to encrypt ECR repositories | `string` | `""` | no |
| <a name="input_profile"></a> [profile](#input\_profile) | Profile of AWS credentials to deploy Terraform sources | `string` | n/a | yes |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | List of ECR repositories to create | `list(any)` | <pre>[<br>  {<br>    "image": "mongo",<br>    "name": "mongodb",<br>    "tag": "4.4.11"<br>  },<br>  {<br>    "image": "redis",<br>    "name": "redis",<br>    "tag": "bullseye"<br>  },<br>  {<br>    "image": "symptoma/activemq",<br>    "name": "activemq",<br>    "tag": "5.16.3"<br>  },<br>  {<br>    "image": "dockerhubaneo/armonik_control",<br>    "name": "armonik-control-plane",<br>    "tag": "0.4.0"<br>  },<br>  {<br>    "image": "dockerhubaneo/armonik_pollingagent",<br>    "name": "armonik-polling-agent",<br>    "tag": "0.4.0"<br>  },<br>  {<br>    "image": "dockerhubaneo/armonik_worker_dll",<br>    "name": "armonik-worker",<br>    "tag": "0.1.2-SNAPSHOT.4.cfda5d1"<br>  },<br>  {<br>    "image": "datalust/seq",<br>    "name": "seq",<br>    "tag": "2021.4"<br>  },<br>  {<br>    "image": "grafana/grafana",<br>    "name": "grafana",<br>    "tag": "latest"<br>  },<br>  {<br>    "image": "prom/prometheus",<br>    "name": "prometheus",<br>    "tag": "latest"<br>  },<br>  {<br>    "image": "k8s.gcr.io/autoscaling/cluster-autoscaler",<br>    "name": "cluster-autoscaler",<br>    "tag": "v1.21.0"<br>  },<br>  {<br>    "image": "amazon/aws-node-termination-handler",<br>    "name": "aws-node-termination-handler",<br>    "tag": "v1.10.0"<br>  },<br>  {<br>    "image": "fluent/fluent-bit",<br>    "name": "fluent-bit",<br>    "tag": "1.3.11"<br>  }<br>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for resource | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ARN of KMS used for ECR |
| <a name="output_repositories"></a> [repositories](#output\_repositories) | List of ECR repositories |
<!-- END_TF_DOCS -->
