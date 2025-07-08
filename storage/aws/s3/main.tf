locals {
  attach_policy = (var.attach_require_latest_tls_policy || var.attach_deny_insecure_transport_policy || var.attach_policy)
  tags          = merge(var.tags, { module = "s3" })
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket        = var.name
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = var.versioning
  }
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.s3_bucket.id
  rule {
    object_ownership = var.ownership
  }
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.s3_bucket.id
  acl    = "private"
  depends_on = [
    aws_s3_bucket_ownership_controls.ownership,
    aws_s3_bucket_public_access_block.s3_bucket
  ]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.s3_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.kms_key_id
    }
  }
}

data "aws_iam_policy_document" "deny_insecure_transport" {
  count = (var.attach_deny_insecure_transport_policy ? 1 : 0)
  statement {
    sid    = "denyInsecureTransport"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.s3_bucket.arn,
      "${aws_s3_bucket.s3_bucket.arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

data "aws_iam_policy_document" "require_latest_tls" {
  count = (var.attach_require_latest_tls_policy ? 1 : 0)
  statement {
    sid    = "denyOutdatedTLS"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.s3_bucket.arn,
      "${aws_s3_bucket.s3_bucket.arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values = [
        "1.2"
      ]
    }
  }
}

data "aws_iam_policy_document" "combined" {
  count = (local.attach_policy ? 1 : 0)
  source_policy_documents = compact([
    var.attach_require_latest_tls_policy ? data.aws_iam_policy_document.require_latest_tls[0].json : "",
    var.attach_deny_insecure_transport_policy ? data.aws_iam_policy_document.deny_insecure_transport[0].json : "",
    var.attach_policy ? var.policy : ""
  ])
}

resource "aws_s3_bucket_policy" "s3_bucket" {
  count  = (local.attach_policy ? 1 : 0)
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.combined[0].json
}

resource "aws_s3_bucket_public_access_block" "s3_bucket" {
  # Chain resources (s3_bucket -> s3_bucket_policy -> s3_bucket_public_access_block)
  # to prevent "A conflicting conditional operation is currently in progress against this resource."
  # Ref: https://github.com/hashicorp/terraform-provider-aws/issues/7628

  count                   = (var.attach_public_policy ? 1 : 0)
  bucket                  = local.attach_policy ? aws_s3_bucket_policy.s3_bucket[0].id : aws_s3_bucket.s3_bucket.id
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

data "aws_iam_policy_document" "s3" {

  statement {
    sid = "AllowBucketAdminActions"
    actions = [
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]
    effect    = "Allow"
    resources = [aws_s3_bucket.s3_bucket.arn]
  }

  statement {
    sid = "AllowObjectAdminActions"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl",
      "s3:GetObjectAcl",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.s3_bucket.arn}/*"]
  }

  statement {
    sid = "AllowBucketLifecycleActions"
    actions = [
      "s3:PutLifecycleConfiguration",
      "s3:GetLifecycleConfiguration",
    ]
    effect    = "Allow"
    resources = [aws_s3_bucket.s3_bucket.arn]
  }
}

resource "aws_iam_policy" "s3" {
  count       = can(coalesce(var.role_name)) ? 1 : 0
  name_prefix = "${var.name}-s3-admin"
  description = "Policy for allowing S3 admin access"
  policy      = data.aws_iam_policy_document.s3.json
  tags        = local.tags
}

resource "aws_iam_policy_attachment" "s3" {
  count      = can(coalesce(var.role_name)) ? 1 : 0
  name       = "${var.name}-s3"
  roles      = [var.role_name]
  policy_arn = aws_iam_policy.s3[0].arn
}
