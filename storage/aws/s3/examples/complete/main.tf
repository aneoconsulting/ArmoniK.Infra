# Current account
data "aws_caller_identity" "current" {}

# this external provider is used to get date during the plan step.
data "external" "static_timestamp" {
  program = ["date", "+{ \"creation_date\": \"%Y/%m/%d %T\" }"]
}

# this resource is just used to prevent change of the creation_date during successive 'terraform apply'
resource "null_resource" "timestamp" {
  triggers = {
    creation_date = data.external.static_timestamp.result.creation_date
  }
  lifecycle {
    ignore_changes = [triggers]
  }
}
# Random alphanumeric
resource "random_string" "random_name" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

module "complete_s3" {
  source                                = "../../../s3"
  name                                  = "test-s3-${random_string.random_name.result}"
  policy                                = ""
  attach_policy                         = false
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
  attach_public_policy                  = false
  block_public_acls                     = true
  block_public_policy                   = true
  ignore_public_acls                    = true
  restrict_public_buckets               = true
  kms_key_id                            = null
  sse_algorithm                         = "aws:kms"
  ownership                             = "BucketOwnerPreferred"
  versioning                            = "Disabled"
  tags = {
    env             = "test"
    app             = "complete"
    module          = "AWS S3"
    "create by"     = data.aws_caller_identity.current.arn
    "creation date" = null_resource.timestamp.triggers["creation_date"]
  }
}
