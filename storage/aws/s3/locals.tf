# Current account
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

locals {
  attach_policy = (var.s3.attach_require_latest_tls_policy || var.s3.attach_deny_insecure_transport_policy || var.s3.attach_policy)
  tags          = merge(var.tags, { module = "s3" })
}
