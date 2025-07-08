# Availability zones
data "aws_subnet" "private_subnet" {
  for_each   = toset(var.vpc_cidr_block_private)
  cidr_block = each.key

  # dummy ternary impose dependency on subnets even though depends_on does not work here
  vpc_id = var.vpc_subnet_ids != null ? var.vpc_id : var.vpc_id
}

locals {
  tags    = merge(var.tags, { module = "efs" })
  encrypt = (var.kms_key_id != "" && var.kms_key_id != null)
}

resource "aws_efs_file_system" "efs" {
  creation_token                  = var.name
  encrypted                       = local.encrypt
  kms_key_id                      = (local.encrypt ? var.kms_key_id : null)
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps

  dynamic "lifecycle_policy" {
    for_each = toset(compact([var.transition_to_ia]))
    content {
      transition_to_ia = lifecycle_policy.key
    }
  }

  tags = local.tags
}

resource "aws_security_group" "efs" {
  name        = "${var.name}-sg"
  description = "Allow EFS inbound traffic on NFS port 2049"
  vpc_id      = var.vpc_id
  ingress {
    description = "tcp from ArmoniK VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = var.vpc_cidr_blocks
  }
  tags = local.tags
}

resource "aws_efs_mount_target" "efs" {
  for_each        = data.aws_subnet.private_subnet
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = each.value.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "efs" {
  for_each       = (var.access_point != null ? toset(var.access_point) : toset([]))
  file_system_id = aws_efs_file_system.efs.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/${each.key}"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 755
    }
  }
  tags = local.tags
}
