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

# Create VPC
module "vpc" {
  source          = "../../../vpc"
  name            = "vpce-simple-${random_string.suffix.result}"
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  tags = {
    env             = "test"
    app             = "simple"
    module          = "AWS VPCE"
    "create by"     = data.aws_caller_identity.current.arn
    "creation date" = null_resource.timestamp.triggers["creation_date"]
  }
}

# Create a VPC endpoint for S3
module "vpce" {
  source = "../../../vpce"
  vpc_id = module.vpc.id
  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
    }
  }
  tags = {
    env             = "test"
    app             = "simple"
    module          = "AWS VPCE"
    "create by"     = data.aws_caller_identity.current.arn
    "creation date" = null_resource.timestamp.triggers["creation_date"]
  }
}
