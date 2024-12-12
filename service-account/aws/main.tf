

locals {
  prefix   = var.prefix
  tags     = merge(var.tags, { module = "aws-service-account" })
  oidc_arn = var.oidc_provider_arn
  oidc_url = trimprefix(var.oidc_issuer_url, "https://")
}

resource "aws_iam_role" "armonik" {
  name = "${local.prefix}-eks-pod-identity-armonik"
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

resource "kubernetes_service_account" "armonik" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.armonik.arn
    }
  }
  automount_service_account_token = var.automount_service_account_token
}
