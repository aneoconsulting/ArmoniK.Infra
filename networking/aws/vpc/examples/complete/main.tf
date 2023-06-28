# Current account
data "aws_caller_identity" "current" {}

# Availability zones
data "aws_availability_zones" "available" {}

# random string
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

# this external provider is used to get date during the plan step.
data "external" "static_timestamp" {
  program = ["date", "+{ \"creation_date\": \"%Y/%m/%d %T\" }"]
}

# this resource is just used to prevent change of the creation_date during successive 'terraform apply'
resource "null_resource" "timestamp" {
  triggers = {
    creation_date = data.external.static_timestamp.result.creation_date
  }
  lifecycle {
    ignore_changes = [triggers]
  }
}

locals {
  azs      = data.aws_availability_zones.available.names
  vpc_cidr = "10.0.0.0/16"
}

module "complete_vpc" {
  source                                          = "../../../vpc"
  name                                            = "complete-${random_string.suffix.result}"
  eks_name                                        = "complete-vpc"
  cidr                                            = local.vpc_cidr
  secondary_cidr_blocks                           = ["20.0.0.0/16"]
  private_subnets                                 = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets                                  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  pod_subnets                                     = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
  enable_external_access                          = true
  flow_log_cloudwatch_log_group_kms_key_id        = null
  flow_log_cloudwatch_log_group_retention_in_days = 30
  flow_log_file_format                            = "plain-text"
  flow_log_max_aggregation_interval               = 60
  use_karpenter                                   = true
  tags = {
    env             = "test"
    app             = "complete"
    module          = "AWS VPC"
    "create by"     = data.aws_caller_identity.current.arn
    "creation date" = null_resource.timestamp.triggers["creation_date"]
  }
}
