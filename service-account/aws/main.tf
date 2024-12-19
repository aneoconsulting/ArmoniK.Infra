

locals {
  prefix = var.prefix
  tags = merge(var.tags, { module = "amazon-sqs" })
  oidc_arn = var.oidc_provider_arn
  oidc_url = trimprefix(var.oidc_issuer_url, "https://")
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
 
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
 
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "armonik" {
  name = "${local.prefix}-eks-pod-identity-armonik"
  #assume_role_policy = data.aws_iam_policy_document.assume_role.json
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_url}:aud" = "sts.amazonaws.com"
            "${local.oidc_url}:sub" = [
              "system:serviceaccount:${var.namespace}:${var.service_account_name}",
            ]
          }
        }
      }
    ]
  })
  tags = local.tags
}

resource "aws_iam_policy_attachment" "armonik_decrypt_object" {
  name       = "${local.prefix}-s3-encrypt-decrypt-armonik"
  roles      = [aws_iam_role.armonik.name]
  policy_arn = var.decrypt_policy_arn
}
 
data "aws_iam_policy_document" "sqs" {
  statement {
    sid = "SqsAdmin"
    actions = [
      "sqs:*"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}
 
resource "aws_iam_policy" "sqs" {
  name_prefix = "${local.prefix}-sqs-admin"
  description = "Policy for allowing SQS admin access"
  policy      = data.aws_iam_policy_document.sqs.json
  tags        = local.tags
}
 
resource "aws_iam_policy_attachment" "sqs" {
  name       = "${local.prefix}-sqs"
  roles      = [aws_iam_role.armonik.name]
  policy_arn = aws_iam_policy.sqs.arn
}
 
data "aws_iam_policy_document" "s3" {
  statement {
    sid = "S3Admin"
    actions = [
      "s3:*"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}
 
resource "aws_iam_policy" "s3" {
  name_prefix = "${local.prefix}-s3-admin"
  description = "Policy for allowing S3 admin access"
  policy      = data.aws_iam_policy_document.s3.json
  tags        = local.tags
}
 
resource "aws_iam_policy_attachment" "s3" {
  name       = "${local.prefix}-s3"
  roles      = [aws_iam_role.armonik.name]
  policy_arn = aws_iam_policy.s3.arn
}
 
resource "kubernetes_service_account" "armonik" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
 
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.armonik.arn
    }
  }
}