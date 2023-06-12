# Current account
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

locals {
  tags = merge(var.tags, { module = "cloudwatch" })
}
