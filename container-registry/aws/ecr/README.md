# AWS ECR

Amazon Elastic Container Registry (Amazon ECR) is a fully managed container registry offering high-performance hosting, so you can reliably deploy application images and artifacts anywhere. 

This module creates AWS ECR with these possibilities :

* Enable or disable mutability
* Enable or disable the scan on push
* Enable or disable the force delete
* Choose the encryption type 
* Set ECR policy on only pull accounts and/or push and pull accounts
* Set a lifecycle policy

This module must be used with these constraints:

* Use the same availability zone to all the repositories
* Give the image name and the tag of the all repositories

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |
| <a name="requirement_skopeo2"></a> [skopeo2](#requirement\_skopeo2) | >= 1.1.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.4.0 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.1 |
| <a name="provider_skopeo2"></a> [skopeo2](#provider\_skopeo2) | >= 1.1.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecr_lifecycle_policy.ecr_lifecycle_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [null_resource.logout_public_ecr](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [skopeo2_copy.copy_images](https://registry.terraform.io/providers/bsquare-corp/skopeo2/latest/docs/resources/copy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecr_authorization_token.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_authorization_token) | data source |
| [aws_iam_policy_document.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.only_pull](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.push_and_pull](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_encryption_type"></a> [encryption\_type](#input\_encryption\_type) | The encryption type to use for the repository. | `string` | `"AES256"` | no |
| <a name="input_force_delete"></a> [force\_delete](#input\_force\_delete) | If true, will delete the repository even if it contains images. | `bool` | `true` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS to encrypt ECR repositories | `string` | `null` | no |
| <a name="input_lifecycle_policy"></a> [lifecycle\_policy](#input\_lifecycle\_policy) | Manages an ECR repository lifecycle policy | `map(any)` | `null` | no |
| <a name="input_mutability"></a> [mutability](#input\_mutability) | The tag mutability setting for the repository | `string` | `"MUTABLE"` | no |
| <a name="input_only_pull_accounts"></a> [only\_pull\_accounts](#input\_only\_pull\_accounts) | List of accounts having pull permission | `list(string)` | `[]` | no |
| <a name="input_push_and_pull_accounts"></a> [push\_and\_pull\_accounts](#input\_push\_and\_pull\_accounts) | List of accounts having push and pull permissions | `list(string)` | `[]` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Map of ECR repositories to create. Each repository is an object of "image" and "tag" parameters | <pre>map(object({<br>    image = string<br>    tag   = string<br>  }))</pre> | `{}` | no |
| <a name="input_scan_on_push"></a> [scan\_on\_push](#input\_scan\_on\_push) | Indicates whether images are scanned after being pushed to the repository or not scanned | `bool` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for resource | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ARN of KMS used for ECR |
| <a name="output_repositories"></a> [repositories](#output\_repositories) | Map of ECR repositories created on AWS |
<!-- END_TF_DOCS -->
