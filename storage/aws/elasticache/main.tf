locals {
  tags                       = merge(var.tags, { module = "elasticache" })
  automatic_failover_enabled = var.multi_az_enabled ? true : var.automatic_failover_enabled
  num_cache_clusters         = (var.automatic_failover_enabled && var.num_cache_clusters < 2) ? 2 : var.num_cache_clusters
  slow_log_name              = try(var.slow_log, "") == "" ? "/aws/elasticache/${var.name}/slow-log" : var.slow_log
  engine_log_name            = try(var.engine_log, "") == "" ? "/aws/elasticache/${var.name}/engine-log" : var.engine_log
  data_tiering_enabled       = var.node_type == "r6gd" ? true : var.data_tiering_enabled
}

# Slow log and engine log not yet available in Terraform
module "slow_log" {
  source            = "../../../monitoring/aws/cloudwatch-log-group"
  name              = local.slow_log_name
  kms_key_id        = var.log_kms_key_id
  retention_in_days = var.log_retention_in_days
  tags              = local.tags
}

module "engine_log" {
  source            = "../../../monitoring/aws/cloudwatch-log-group"
  name              = local.engine_log_name
  kms_key_id        = var.log_kms_key_id
  retention_in_days = var.log_retention_in_days
  tags              = local.tags
}

resource "aws_elasticache_replication_group" "elasticache" {
  description                 = "Replication group for stdin and stdout elasticache cluster"
  replication_group_id        = var.name
  engine                      = var.engine
  engine_version              = var.engine_version
  node_type                   = var.node_type
  port                        = 6379
  apply_immediately           = var.apply_immediately
  multi_az_enabled            = var.multi_az_enabled
  automatic_failover_enabled  = local.automatic_failover_enabled # if enabled num_cache_cluster must be > 1
  num_cache_clusters          = local.num_cache_clusters
  preferred_cache_cluster_azs = var.preferred_cache_cluster_azs
  data_tiering_enabled        = local.data_tiering_enabled # if node type is r6gd
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  kms_key_id                  = var.kms_key_id
  parameter_group_name        = aws_elasticache_parameter_group.elasticache.name
  security_group_ids          = [aws_security_group.elasticache.id]
  subnet_group_name           = aws_elasticache_subnet_group.elasticache.name
  log_delivery_configuration {
    destination      = module.slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }
  log_delivery_configuration {
    destination      = module.engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }
  tags = local.tags
  depends_on = [
    aws_elasticache_parameter_group.elasticache,
    aws_security_group.elasticache,
    aws_elasticache_subnet_group.elasticache,
  ]
}

resource "aws_elasticache_parameter_group" "elasticache" {
  name   = "${var.name}-config"
  family = "redis6.x"
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
  dynamic "parameter" {
    for_each = var.max_memory_samples == "" ? [] : [1]
    content {
      name  = "maxmemory-samples"
      value = var.max_memory_samples
    }
  }
  tags = local.tags
}

resource "aws_security_group" "elasticache" {
  name        = "${var.name}-sg"
  description = "Allow Redis Elasticache inbound traffic on port 6379"
  vpc_id      = var.vpc_id
  ingress {
    description = "tcp from ArmoniK VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

# Subnet group for Elasticache IP
resource "aws_elasticache_subnet_group" "elasticache" {
  description = "Subnet ids for IO of ArmoniK AWS Elasticache"
  name        = "${var.name}-io"
  subnet_ids  = var.vpc_subnet_ids
  tags        = local.tags
}
