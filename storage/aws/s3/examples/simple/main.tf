# Current account
data "aws_caller_identity" "current" {}

# this external provider is used to get date during the plan step.
data "external" "static_timestamp" {
  program = ["date", "+{ \"creation_date\": \"%Y/%m/%d %T\" }"]
}
# Random alphanumeric
resource "random_string" "random_name" {
  length  = 5
  special = false
  upper   = false
  numeric = true
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

module "simple_s3" {
  source = "../../../s3"
  name   = "test-s3-${random_string.random_name.result}"
  tags = {
    env             = "test"
    app             = "simple"
    module          = "AWS S3"
    "create by"     = data.aws_caller_identity.current.arn
    "creation date" = null_resource.timestamp.triggers["creation_date"]
  }
}
