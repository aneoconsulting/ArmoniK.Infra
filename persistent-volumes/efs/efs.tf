# AWS EFS
module "efs" {
  source = "../../aws/efs"
  tags   = local.tags
  vpc    = var.vpc
  efs    = var.efs
}