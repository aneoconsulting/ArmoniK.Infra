resource "aws_cloudwatch_log_group" "log_group" {
  region                      = var.region
  name                        = var.name
  kms_key_id                  = var.kms_key_id
  retention_in_days           = var.retention_in_days
  log_group_class             = var.log_group_class
  deletion_protection_enabled = var.deletion_protection_enabled
  tags                        = local.tags
}
