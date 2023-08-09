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
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
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
  depends_on = [aws_iam_role.efs_csi_driver]
}
