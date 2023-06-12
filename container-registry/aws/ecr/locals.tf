# Current account
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

locals {
  region = data.aws_region.current.name
  tags   = merge({ module = "ecr" }, var.tags)
}
