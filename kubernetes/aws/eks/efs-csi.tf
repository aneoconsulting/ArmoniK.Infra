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
            #"${local.oidc_url}:aud" = "sts.amazonaws.com"
            "${local.oidc_url}:sub" = "system:serviceaccount:${local.efs_csi_namespace}:efs-csi-controller-sa"
          }
        }
      }
    ]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver" {
  policy_arn = aws_iam_policy.efs_csi_driver.arn
  role       = aws_iam_role.efs_csi_driver.name
}

resource "kubernetes_service_account" "efs_csi_driver" {
  metadata {
    name = "efs-csi-controller-sa"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.efs_csi_driver.arn
    }
    namespace = local.efs_csi_namespace
  }
}

resource "helm_release" "efs_csi" {
  name       = "efs-csi"
  namespace  = kubernetes_service_account.efs_csi_driver.metadata[0].namespace
  chart      = "aws-efs-csi-driver"
  repository = var.eks.efs_csi.repository
  version    = var.eks.efs_csi.version

  set {
    name  = "image.repository"
    value = var.eks.docker_images.efs_csi.image
  }
  set {
    name  = "image.tag"
    value = var.eks.docker_images.efs_csi.tag
  }
  set {
    name  = "sidecars.livenessProbe.image.repository"
    value = var.eks.docker_images.livenessprobe.image
  }
  set {
    name  = "sidecars.livenessProbe.image.tag"
    value = var.eks.docker_images.livenessprobe.tag
  }
  set {
    name  = "sidecars.nodeDriverRegistrar.image.repository"
    value = var.eks.docker_images.node_driver_registrar.image
  }
  set {
    name  = "sidecars.nodeDriverRegistrar.image.tag"
    value = var.eks.docker_images.node_driver_registrar.tag
  }
  set {
    name  = "sidecars.csiProvisioner.image.repository"
    value = var.eks.docker_images.external_provisioner.image
  }
  set {
    name  = "sidecars.csiProvisioner.image.tag"
    value = var.eks.docker_images.external_provisioner.tag
  }
  set {
    name  = "imagePullSecrets"
    value = var.eks.efs_csi.image_pull_secrets
  }

  values = [
    yamlencode(local.controller)
  ]
  depends_on = [kubernetes_service_account.efs_csi_driver]
}
