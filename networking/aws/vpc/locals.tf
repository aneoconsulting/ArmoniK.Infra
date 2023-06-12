# Current account
data "aws_caller_identity" "current" {}

locals {
  tags = merge({ module = "vpc" }, var.tags)
}
