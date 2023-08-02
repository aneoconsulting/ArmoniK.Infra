# AWS EFS
module "efs" {
  source                          = "../../../storage/aws/efs"
  tags                            = local.tags
  vpc_id                          = var.vpc_id
  vpc_cidr_block_private          = var.vpc_cidr_block_private
  vpc_cidr_blocks                 = var.vpc_cidr_blocks
  vpc_subnet_ids                  = var.vpc_subnet_ids
  name                            = var.name
  kms_key_id                      = var.kms_key_id
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps
  transition_to_ia                = var.transition_to_ia
  access_point                    = var.access_point
}
