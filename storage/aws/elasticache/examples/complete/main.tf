# Current account
data "aws_caller_identity" "current" {}

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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "elasticache" {
  source                      = "../../../elasticache"
  name                        = "test-elasticache"
  engine                      = "redis"
  engine_version              = "6.x"
  node_type                   = "cache.r4.large"
  apply_immediately           = true
  multi_az_enabled            = false
  automatic_failover_enabled  = true
  num_cache_clusters          = 2
  preferred_cache_cluster_azs = []
  data_tiering_enabled        = false
  log_retention_in_days       = 30
  slow_log                    = ""
  engine_log                  = ""
  kms_key_id                  = null
  log_kms_key_id              = null
  tags = {
    env             = "test"
    app             = "complete"
    module          = "AWS S3"
    "create by"     = data.aws_caller_identity.current.arn
    "creation date" = null_resource.timestamp.triggers["creation_date"]
  }
  vpc_cidr_blocks = [data.aws_vpc.default.cidr_block]
  vpc_id          = data.aws_vpc.default.id
  vpc_subnet_ids  = data.aws_subnets.subnets.ids
}
