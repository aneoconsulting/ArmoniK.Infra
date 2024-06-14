# Availability zones
data "aws_availability_zones" "available" {}

locals {
  tags                          = merge(var.tags, { module = "vpc" })
  kubernetes_public_subnet_tags = can(coalesce(var.eks_name)) ? { "kubernetes.io/role/elb" = 1 } : null
  kubernetes_private_subnet_tags = can(coalesce(var.eks_name)) ? merge({
    "kubernetes.io/role/internal-elb" = 1
  }, (var.use_karpenter ? { "karpenter.sh/discovery" = var.eks_name } : null)) : null
  secondary_cidr_blocks  = can(coalesce(var.eks_name)) ? distinct(compact(concat(var.secondary_cidr_blocks, var.pod_subnets))) : var.secondary_cidr_blocks
  private_subnets        = can(coalesce(var.eks_name)) ? distinct(compact(concat(var.private_subnets, var.pod_subnets))) : var.private_subnets
  enable_external_access = length(var.public_subnets) != 0
}

# VPC
module "vpc" {
  source                = "terraform-aws-modules/vpc/aws"
  version               = "5.8.1"
  name                  = var.name
  azs                   = data.aws_availability_zones.available.names
  cidr                  = var.cidr
  secondary_cidr_blocks = local.secondary_cidr_blocks
  private_subnets       = local.private_subnets
  public_subnets        = var.public_subnets
  # DNS info, required for private endpoint
  enable_dns_hostnames = true
  enable_dns_support   = true
  # External access
  enable_nat_gateway = local.enable_external_access
  single_nat_gateway = local.enable_external_access
  # Cloudwatch log group and IAM role will be created
  enable_flow_log                                 = true
  flow_log_destination_type                       = "cloud-watch-logs"
  flow_log_file_format                            = var.flow_log_file_format
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_max_aggregation_interval               = var.flow_log_max_aggregation_interval
  flow_log_cloudwatch_log_group_name_prefix       = "/aws/${var.name}-vpc-flow-logs/"
  flow_log_cloudwatch_log_group_kms_key_id        = var.flow_log_cloudwatch_log_group_kms_key_id
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_cloudwatch_log_group_retention_in_days
  # tags
  tags              = local.tags
  vpc_flow_log_tags = local.tags
  private_subnet_tags = merge(local.tags, local.kubernetes_private_subnet_tags, {
    Tier = "Private"
  })
  public_subnet_tags = merge(local.tags, local.kubernetes_public_subnet_tags, {
    Tier = "Public"
  })
}

# Pod subnets
data "aws_subnet" "pod_subnets" {
  for_each   = can(coalesce(var.eks_name)) ? toset(var.pod_subnets) : []
  vpc_id     = module.vpc.vpc_id
  cidr_block = each.key
  depends_on = [module.vpc]
}
