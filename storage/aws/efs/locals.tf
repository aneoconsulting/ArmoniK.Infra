# Availability zones
data "aws_subnet" "private_subnet" {
  for_each   = toset(var.vpc.cidr_block_private)
  cidr_block = each.key

  # dummy ternary impose dependency on subnets even though depends_on does not work here
  vpc_id = var.vpc.subnet_ids != null ? var.vpc.id : var.vpc.id
}

locals {
  tags       = merge(var.tags, { module = "efs" })
  encrypt    = (var.efs.kms_key_id != "" && var.efs.kms_key_id != null)
  subnet_ids = flatten([for key, value in { for subnet in data.aws_subnet.private_subnet : subnet.availability_zone_id => subnet.id... } : value[0]])
}
