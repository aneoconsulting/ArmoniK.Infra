locals {
  # ebs CSI
  ebs_csi = {
    name                                  = coalesce(var.ebs_csi.name, "${var.name}-ebs-csi-driver")
    oidc_arn                              = module.eks.oidc_provider_arn
    oidc_url                              = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")
    namespace                             = coalesce(var.ebs_csi.namespace, "kube-system")
    kubernetes_service_account_controller = "ebs-csi-controller-sa"
    kubernetes_service_account_node       = "ebs-csi-node-sa"

    tolerations = var.node_selector != {} ? [
      for key, value in var.node_selector : {
        key      = key
        operator = "Equal"
        value    = value
        effect   = "NoSchedule"
      }
    ] : []
  }

  ebs_csi_controller = {
    controller = {
      logLevel            = 2
      extraCreateMetadata = true
      podAnnotations      = {}
      resources           = var.ebs_csi.controller_resources
      nodeSelector        = var.node_selector
      tolerations         = local.ebs_csi.tolerations
      affinity            = {}
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.ebs_csi_driver_controller.metadata[0].name
      }
    }
  }
}

# Simpler IAM policies
# data "aws_iam_policy_document" "ebs_csi_driver" {
#   statement {
#     actions = [
#       "ec2:CreateVolume",
#       "ec2:AttachVolume",
#       "ec2:DetachVolume",
#       "ec2:DeleteVolume",
#       "ec2:CreateSnapshot",
#       "ec2:DeleteSnapshot",
#       "ec2:DescribeVolumes",
#       "ec2:DescribeSnapshots",
#       "ec2:DescribeInstances",
#       "ec2:DescribeAvailabilityZones",
#       "ec2:DescribeVolumeStatus",
#       "ec2:DescribeVolumeAttribute",
#       "ec2:DescribeSnapshotAttribute",
#       "ec2:DescribeInstanceAttribute",
#       "ec2:DescribeInstanceCreditSpecifications",
#       "ec2:DescribeVolumeTypes",
#       "ec2:DescribeVpcAttribute",
#       "ec2:DescribeVpcEndpoints",
#       "ec2:DescribeVpcs",
#       "ec2:ModifyVolume",
#       "ec2:ModifyVolumeAttribute",
#       "ec2:ModifyInstanceAttribute",
#       "ec2:CreateTags",
#       "ec2:DeleteTags"
#     ]
#     effect    = "Allow"
#     resources = ["*"]
#   }
# }

# Allow EKS and the driver to interact with ebs
data "aws_iam_policy_document" "ebs_csi_driver" {
  statement {
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:ModifyVolume"
    ]
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:volume/*"]
  }
  statement {
    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:instance/*"
    ]
  }
  statement {
    actions = [
      "ec2:CreateVolume",
      "ec2:EnableFastSnapshotRestores"
    ]
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
  }
  statement {
    actions = [
      "ec2:CreateTags"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*"
    ]
    condition {
      test = "StringEquals"
      values = [
        "CreateVolume",
        "CreateSnapshot"
      ]
      variable = "ec2:CreateAction"
    }
  }
  statement {
    actions = ["ec2:DeleteTags"]
    effect  = "Allow"
    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*"
    ]
  }
  statement {
    actions   = ["ec2:CreateVolume"]
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:volume/*"]
    condition {
      test     = "StringLike"
      values   = [true]
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
    }
  }
  statement {
    actions   = ["ec2:CreateVolume"]
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:volume/*"]
    condition {
      test     = "StringLike"
      values   = ["*"]
      variable = "aws:RequestTag/CSIVolumeName"
    }
  }
  statement {
    actions   = ["ec2:DeleteVolume"]
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:volume/*"]
    condition {
      test     = "StringLike"
      values   = [true]
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
    }
  }
  statement {
    actions   = ["ec2:DeleteVolume"]
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:volume/*"]
    condition {
      test     = "StringLike"
      values   = ["*"]
      variable = "ec2:ResourceTag/CSIVolumeName"
    }
  }
  statement {
    actions   = ["ec2:DeleteVolume"]
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:volume/*"]
    condition {
      test     = "StringLike"
      values   = ["*"]
      variable = "ec2:ResourceTag/kubernetes.io/created-for/pvc/name"
    }
  }
  statement {
    actions   = ["ec2:CreateSnapshot"]
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    condition {
      test     = "StringLike"
      values   = ["*"]
      variable = "aws:RequestTag/CSIVolumeSnapshotName"
    }
  }
  statement {
    actions   = ["ec2:CreateSnapshot"]
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    condition {
      test     = "StringLike"
      values   = [true]
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
    }
  }
  statement {
    actions   = ["ec2:DeleteSnapshot"]
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    condition {
      test     = "StringLike"
      values   = ["*"]
      variable = "ec2:ResourceTag/CSIVolumeSnapshotName"
    }
  }
  statement {
    actions   = ["ec2:DeleteSnapshot"]
    effect    = "Allow"
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    condition {
      test     = "StringLike"
      values   = [true]
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
    }
  }
}

resource "aws_iam_policy" "ebs_csi_driver" {
  name_prefix = local.ebs_csi.name
  description = "Policy to allow EKS and the driver to interact with EBS"
  policy      = data.aws_iam_policy_document.ebs_csi_driver.json
  tags        = local.tags
}

resource "aws_iam_role" "ebs_csi_driver" {
  name = local.ebs_csi.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.ebs_csi.oidc_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.ebs_csi.oidc_url}:aud" = "sts.amazonaws.com"
            "${local.ebs_csi.oidc_url}:sub" = [
              "system:serviceaccount:${local.ebs_csi.namespace}:${local.ebs_csi.kubernetes_service_account_controller}",
              "system:serviceaccount:${local.ebs_csi.namespace}:${local.ebs_csi.kubernetes_service_account_node}"
            ]
          }
        }
      }
    ]
  })
  tags       = local.tags
  depends_on = [aws_iam_policy.ebs_csi_driver]
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = aws_iam_policy.ebs_csi_driver.arn
  role       = aws_iam_role.ebs_csi_driver.name
}

resource "kubernetes_service_account" "ebs_csi_driver_controller" {
  metadata {
    name = local.ebs_csi.kubernetes_service_account_controller
    annotations = {
      "eks.amazonaws.com/role-arn"     = aws_iam_role.ebs_csi_driver.arn
      "app.kubernetes.io/managed-by"   = "Helm"
      "meta.helm.sh/release-name"      = "ebs-csi"
      "meta.helm.sh/release-namespace" = "kube-system"
    }
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    namespace = local.ebs_csi.namespace
  }
  depends_on = [null_resource.update_kubeconfig]
}

resource "kubernetes_service_account" "ebs_csi_driver_node" {
  metadata {
    name = local.ebs_csi.kubernetes_service_account_node
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_driver.arn
    }
    namespace = local.ebs_csi.namespace
  }
  depends_on = [null_resource.update_kubeconfig]
}

resource "helm_release" "ebs_csi" {
  name       = "ebs-csi"
  namespace  = kubernetes_service_account.ebs_csi_driver_controller.metadata[0].namespace
  chart      = "aws-ebs-csi-driver"
  repository = var.ebs_csi.repository
  version    = var.ebs_csi.version

  set {
    name  = "image.repository"
    value = var.ebs_csi.image
  }
  set {
    name  = "image.tag"
    value = var.ebs_csi.tag
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
    name  = "sidecars.provisioner.image.repository"
    value = var.csi_external_provisioner.image
  }
  set {
    name  = "sidecars.provisioner.image.tag"
    value = var.csi_external_provisioner.tag
  }
  dynamic "set" {
    for_each = toset(compact([var.ebs_csi.image_pull_secrets]))
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
    value = kubernetes_service_account.ebs_csi_driver_node.metadata[0].name
  }
  values = [
    yamlencode(local.ebs_csi_controller)
  ]
  depends_on = [
    kubernetes_service_account.ebs_csi_driver_controller,
    kubernetes_service_account.ebs_csi_driver_node
  ]
}
