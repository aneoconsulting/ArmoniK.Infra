locals {
  tags = merge(var.tags, { module = "cloudwatch" })
}
