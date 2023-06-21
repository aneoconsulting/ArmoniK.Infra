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
  eks_name        = "complete-vpce"
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  tags = {
    env             = "test"
    app             = "complete"
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
      route_table_ids = flatten([
        module.vpc.this.intra_route_table_ids,
        module.vpc.this.private_route_table_ids,
        module.vpc.this.public_route_table_ids
      ])
      auto_accept     = false
      policy          = null
      ip_address_type = null
      tags            = { vpce = "s3" }
    }
    ec2_autoscaling = {
      service             = "autoscaling"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    ec2 = {
      service             = "ec2"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    ecr_api = {
      service             = "ecr.api"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    logs = {
      service             = "logs"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    sts = {
      service             = "sts"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    ssmmessages = {
      service             = "ssmmessages"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    elasticloadbalancing = {
      service             = "elasticloadbalancing"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
    monitoring = {
      service             = "monitoring"
      service_type        = "Interface"
      private_dns_enabled = !module.vpc.enable_external_access
      subnet_ids          = !module.vpc.enable_external_access ? module.vpc.private_subnets : []
      security_group_ids  = !module.vpc.enable_external_access ? [module.vpc.this.default_security_group_id] : []
    }
  }
  security_group_ids = []
  subnet_ids         = []
  tags = {
    env             = "test"
    app             = "complete"
    module          = "AWS VPCE"
    "create by"     = data.aws_caller_identity.current.arn
    "creation date" = null_resource.timestamp.triggers["creation_date"]
  }
  timeouts = {
    create = "10m"
    update = "15m"
    delete = "20m"
  }
}
