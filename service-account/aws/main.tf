

locals {
  prefix   = var.prefix
  tags     = merge(var.tags, { module = "aws-service-account" })
  oidc_arn = var.oidc_provider_arn
  oidc_url = trimprefix(var.oidc_issuer_url, "https://")
}

# Both mechanisms are always trusted, so switching pod_identity never breaks a running pod; the Pod Identity
# statement follows https://docs.aws.amazon.com/eks/latest/userguide/pod-id-role.html.
data "aws_iam_policy_document" "armonik_trust" {
  statement {
    sid     = "Irsa"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.name}"]
    }
  }
  statement {
    sid     = "PodIdentity"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    dynamic "condition" {
      for_each = var.cluster_name == null ? [] : [var.cluster_name]
      content {
        test     = "StringEquals"
        variable = "aws:RequestTag/eks-cluster-name"
        values   = [condition.value]
      }
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = [var.namespace]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = [var.name]
    }
  }
}

resource "aws_iam_role" "armonik" {
  name               = "${local.prefix}-eks-pod-identity-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.armonik_trust.json
  tags               = local.tags
}

resource "kubernetes_service_account" "armonik" {
  metadata {
    name      = var.name
    namespace = var.namespace

    annotations = var.pod_identity ? {} : {
      "eks.amazonaws.com/role-arn" = aws_iam_role.armonik.arn
    }
  }
  automount_service_account_token = var.automount_token
}

resource "aws_eks_pod_identity_association" "armonik" {
  count           = var.pod_identity ? 1 : 0
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = kubernetes_service_account.armonik.metadata[0].name
  role_arn        = aws_iam_role.armonik.arn
  tags            = local.tags
  lifecycle {
    precondition {
      condition     = var.cluster_name != null
      error_message = "pod_identity requires cluster_name."
    }
  }
}
