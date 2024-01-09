# AWS EFS
module "efs" {
  source = "../../../storage/aws/efs"
  tags   = local.tags
  vpc    = var.vpc
  efs    = var.efs
}

