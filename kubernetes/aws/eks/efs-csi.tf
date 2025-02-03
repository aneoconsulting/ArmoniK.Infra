locals {
  # EFS CSI
  efs_csi_name                          = coalesce(var.efs_csi.name, "${var.name}-efs-csi-driver")
  oidc_arn                              = module.eks.oidc_provider_arn
  oidc_url                              = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")
  efs_csi_namespace                     = coalesce(var.efs_csi.namespace, "kube-system")
  kubernetes_service_account_controller = "efs-csi-controller-sa"
  kubernetes_service_account_node       = "efs-csi-node-sa"
  efs_csi_tolerations = [
    for index in range(0, length(local.node_selector_keys)) : {
      key      = local.node_selector_keys[index]
      operator = "Equal"
      value    = local.node_selector_values[index]
      effect   = "NoSchedule"
    }
  ]
  controller = {
    controller = {
      create                   = true
      logLevel                 = 2
      extraCreateMetadata      = true
      tags                     = {}
      deleteAccessPointRootDir = false
      volMetricsOptIn          = false
      podAnnotations           = {}
      resources                = var.efs_csi.controller_resources
      nodeSelector             = var.node_selector
      tolerations              = local.efs_csi_tolerations
      affinity                 = {}
      serviceAccount = {
        create      = false
        name        = kubernetes_service_account.efs_csi_driver_controller.metadata[0].name
        annotations = {}
      }
      healthPort           = 9909
      regionalStsEndpoints = false
    }
  }
}

# Allow EKS and the driver to interact with EFS
data "aws_iam_policy_document" "efs_csi_driver" {
  statement {
    sid = "Describe"
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
      "ec2:DescribeAvailabilityZones"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "Create"
    actions = [
      "elasticfilesystem:CreateAccessPoint"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringLike"
      values   = [true]
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
    }
  }
  statement {
    sid = "Delete"
    actions = [
      "elasticfilesystem:DeleteAccessPoint"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = [true]
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
    }
  }
  statement {
    sid = "TagResource"
    actions = [
      "elasticfilesystem:TagResource"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringLike"
      values   = [true]
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
    }
  }
  statement {
    sid = "Mount"
    actions = [
      "elasticfilesystem:ClientRootAccess",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientMount"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "efs_csi_driver" {
  name_prefix = local.efs_csi_name
  description = "Policy to allow EKS and the driver to interact with EFS"
  policy      = data.aws_iam_policy_document.efs_csi_driver.json
  tags        = local.tags
}

resource "aws_iam_role" "efs_csi_driver" {
  name = local.efs_csi_name
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
              "system:serviceaccount:${local.efs_csi_namespace}:${local.kubernetes_service_account_controller}",
              "system:serviceaccount:${local.efs_csi_namespace}:${local.kubernetes_service_account_node}"
            ]
          }
        }
      }
    ]
  })
  tags       = local.tags
  depends_on = [aws_iam_policy.efs_csi_driver]
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  policy_arn = aws_iam_policy.efs_csi_driver.arn
  role       = aws_iam_role.efs_csi_driver.name
}

resource "kubernetes_service_account" "efs_csi_driver_controller" {
  metadata {
    name = local.kubernetes_service_account_controller
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.efs_csi_driver.arn
    }
    namespace = local.efs_csi_namespace
  }
}

resource "kubernetes_service_account" "efs_csi_driver_node" {
  metadata {
    name = local.kubernetes_service_account_node
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.efs_csi_driver.arn
    }
    namespace = local.efs_csi_namespace
  }
}

resource "helm_release" "efs_csi" {
  name       = "efs-csi"
  namespace  = kubernetes_service_account.efs_csi_driver_controller.metadata[0].namespace
  chart      = "aws-efs-csi-driver"
  repository = var.efs_csi.repository
  version    = var.efs_csi.version

  set {
    name  = "image.repository"
    value = var.efs_csi.image
  }
  set {
    name  = "image.tag"
    value = var.efs_csi.tag
  }
  set {
    name  = "sidecars.livenessProbe.image.repository"
    value = var.csi_liveness_probe.image
  }
  set {
    name  = "sidecars.livenessProbe.image.tag"
    value = var.csi_liveness_probe.tag
  }
  set {
    name  = "sidecars.nodeDriverRegistrar.image.repository"
    value = var.csi_node_driver_registrar.image
  }
  set {
    name  = "sidecars.nodeDriverRegistrar.image.tag"
    value = var.csi_node_driver_registrar.tag
  }
  set {
    name  = "sidecars.csiProvisioner.image.repository"
    value = var.csi_external_provisioner.image
  }
  set {
    name  = "sidecars.csiProvisioner.image.tag"
    value = var.csi_external_provisioner.tag
  }
  dynamic "set" {
    for_each = toset(compact([var.efs_csi.image_pull_secrets]))
    content {
      name  = "imagePullSecrets"
      value = each.key
    }
  }
  set {
    name  = "node.serviceAccount.create"
    value = false
  }
  set {
    name  = "node.serviceAccount.name"
    value = kubernetes_service_account.efs_csi_driver_node.metadata[0].name
  }
  values = [
    yamlencode(local.controller)
  ]
  depends_on = [
    kubernetes_service_account.efs_csi_driver_controller,
    kubernetes_service_account.efs_csi_driver_node
  ]
}
