# Current account
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

# Current partition
data "aws_partition" "current" {}

# KMS alias
resource "aws_kms_alias" "kms_alias" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.kms.id
}

# KMS key
resource "aws_kms_key" "kms" {
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check
  customer_master_key_spec           = var.customer_master_key_spec
  deletion_window_in_days            = var.deletion_window_in_days
  description                        = var.description
  enable_key_rotation                = var.enable_key_rotation
  is_enabled                         = var.is_enabled
  key_usage                          = var.key_usage
  multi_region                       = var.multi_region
  policy                             = coalesce(var.policy, data.aws_iam_policy_document.policy[0].json)

  tags = var.tags
}

# KMS policy
data "aws_iam_policy_document" "policy" {
  count = var.create ? 1 : 0

  source_policy_documents   = var.source_policy_documents
  override_policy_documents = var.override_policy_documents

  # Default policy - account wide access to all key operations
  dynamic "statement" {
    for_each = var.enable_default_policy ? [1] : []

    content {
      sid       = "Default"
      actions   = ["kms:*"]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
      }
    }
  }

  # Key owner - all key operations
  dynamic "statement" {
    for_each = length(var.key_owners) > 0 ? [1] : []

    content {
      sid       = "KeyOwner"
      actions   = ["kms:*"]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_owners
      }
    }
  }

  # Key administrators - https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators
  dynamic "statement" {
    for_each = length(var.key_administrators) > 0 ? [1] : []

    content {
      sid = "KeyAdministration"
      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_administrators
      }
    }
  }

  # Key users - https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-users
  dynamic "statement" {
    for_each = length(var.key_users) > 0 ? [1] : []

    content {
      sid = "KeyUsage"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_users
      }
    }
  }

  # Key service users - https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-service-integration
  dynamic "statement" {
    for_each = length(var.key_service_users) > 0 ? [1] : []

    content {
      sid = "KeyServiceUsage"
      actions = [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_service_users
      }

      condition {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values   = [true]
      }
    }
  }

  # Key service roles for autoscaling - https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html#policy-example-cmk-access
  dynamic "statement" {
    for_each = length(var.key_service_roles_for_autoscaling) > 0 ? [1] : []

    content {
      sid = "KeyServiceRolesASG"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_service_roles_for_autoscaling
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.key_service_roles_for_autoscaling) > 0 ? [1] : []

    content {
      sid = "KeyServiceRolesASGPersistentVol"
      actions = [
        "kms:CreateGrant"
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_service_roles_for_autoscaling
      }

      condition {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values   = [true]
      }
    }
  }

  # Key cryptographic operations - https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-users-crypto
  dynamic "statement" {
    for_each = length(var.key_symmetric_encryption_users) > 0 ? [1] : []

    content {
      sid = "KeySymmetricEncryption"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_symmetric_encryption_users
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.key_hmac_users) > 0 ? [1] : []

    content {
      sid = "KeyHMAC"
      actions = [
        "kms:DescribeKey",
        "kms:GenerateMac",
        "kms:VerifyMac",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_hmac_users
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.key_asymmetric_public_encryption_users) > 0 ? [1] : []

    content {
      sid = "KeyAsymmetricPublicEncryption"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:DescribeKey",
        "kms:GetPublicKey",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_asymmetric_public_encryption_users
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.key_asymmetric_sign_verify_users) > 0 ? [1] : []

    content {
      sid = "KeyAsymmetricSignVerify"
      actions = [
        "kms:DescribeKey",
        "kms:GetPublicKey",
        "kms:Sign",
        "kms:Verify",
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.key_asymmetric_sign_verify_users
      }
    }
  }

  # https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/access-control-managing-permissions.html#KMS-key-policy-for-DNSSEC
  dynamic "statement" {
    for_each = var.enable_route53_dnssec ? [1] : []

    content {
      sid = "Route53DnssecService"
      actions = [
        "kms:DescribeKey",
        "kms:GetPublicKey",
        "kms:Sign",
      ]
      resources = ["*"]

      principals {
        type        = "Service"
        identifiers = ["dnssec-route53.${data.aws_partition.current.dns_suffix}"]
      }
    }
  }

  # https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/access-control-managing-permissions.html#KMS-key-policy-for-DNSSEC
  dynamic "statement" {
    for_each = var.enable_route53_dnssec ? [1] : []

    content {
      sid       = "Route53DnssecGrant"
      actions   = ["kms:CreateGrant"]
      resources = ["*"]

      principals {
        type        = "Service"
        identifiers = ["dnssec-route53.${data.aws_partition.current.dns_suffix}"]
      }

      condition {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values   = ["true"]
      }

      dynamic "condition" {
        for_each = var.route53_dnssec_sources

        content {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = try(condition.value.account_ids, [data.aws_caller_identity.current.account_id])
        }
      }

      dynamic "condition" {
        for_each = var.route53_dnssec_sources

        content {
          test     = "ArnLike"
          variable = "aws:SourceArn"
          values   = [try(condition.value.hosted_zone_arn, "arn:${data.aws_partition.current.partition}:route53:::hostedzone/*")]
        }
      }
    }
  }

  dynamic "statement" {
    for_each = var.key_statements

    content {
      sid           = try(statement.value.sid, null)
      actions       = try(statement.value.actions, null)
      not_actions   = try(statement.value.not_actions, null)
      effect        = try(statement.value.effect, null)
      resources     = try(statement.value.resources, null)
      not_resources = try(statement.value.not_resources, null)

      dynamic "principals" {
        for_each = try(statement.value.principals, [])

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = try(statement.value.not_principals, [])

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])

        content {
          test     = condition.value.test
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
  statement {
    sid    = "Supported resources"
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      type        = "AWS"
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    condition {
      test = "StringEquals"
      values = [
        "ec2.${data.aws_region.current.name}.amazonaws.com",
        "s3.${data.aws_region.current.name}.amazonaws.com",
        "dynamodb.${data.aws_region.current.name}.amazonaws.com",
        "ecr.${data.aws_region.current.name}.amazonaws.com",
        "eks.${data.aws_region.current.name}.amazonaws.com",
        "elasticache.${data.aws_region.current.name}.amazonaws.com",
        "mq.${data.aws_region.current.name}.amazonaws.com",
      ]
      variable = "kms:ViaService"
    }
  }
}
