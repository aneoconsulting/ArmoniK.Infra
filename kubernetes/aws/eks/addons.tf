locals {
  # Drops null settings so the add-on keeps its own defaults for them.
  ebs_csi_controller = { for k, v in {
    logLevel     = 2
    nodeSelector = var.node_selector
    tolerations  = local.tolerations.tolerations
    resources    = var.ebs_csi.controller_resources
  } : k => v if v != null }

  efs_csi_controller = { for k, v in {
    logLevel                 = 2
    deleteAccessPointRootDir = false
    nodeSelector             = var.node_selector
    tolerations              = local.tolerations.tolerations
    resources                = var.efs_csi.controller_resources
  } : k => v if v != null }

  # One ENIConfig per pod subnet, named after its availability zone (ENI_CONFIG_LABEL_DEF).
  eni_configs = {
    for index, id in var.vpc_pods_subnet_ids : element(data.aws_availability_zones.available.names, index) => {
      id             = id
      securityGroups = [module.eks.node_security_group_id]
    }
  }

  # resolve_conflicts_on_create = OVERWRITE adopts the objects of a cluster that ran these components self-managed.
  addons = {
    vpc-cni = {
      before_compute              = true
      resolve_conflicts_on_create = "OVERWRITE"
      configuration_values = jsonencode(merge({
        enableWindowsIpam             = "true"
        enableWindowsPrefixDelegation = "true"
        env = {
          ENI_CONFIG_LABEL_DEF = "topology.kubernetes.io/zone"
        }
        }, length(local.eni_configs) == 0 ? {} : {
        eniConfig = {
          create  = true
          region  = local.region
          subnets = local.eni_configs
        }
      }))
    }
    kube-proxy = {
      resolve_conflicts_on_create = "OVERWRITE"
    }
    coredns = {
      resolve_conflicts_on_create = "OVERWRITE"
      configuration_values = jsonencode({
        nodeSelector = var.node_selector
        tolerations  = local.tolerations.tolerations
      })
    }
    aws-ebs-csi-driver = {
      addon_version               = var.ebs_csi.addon_version
      resolve_conflicts_on_create = "OVERWRITE"
      service_account_role_arn    = aws_iam_role.ebs_csi_driver.arn
      configuration_values        = jsonencode({ controller = local.ebs_csi_controller })
    }
    aws-efs-csi-driver = {
      addon_version               = var.efs_csi.addon_version
      resolve_conflicts_on_create = "OVERWRITE"
      service_account_role_arn    = aws_iam_role.efs_csi_driver.arn
      configuration_values        = jsonencode({ controller = local.efs_csi_controller })
    }
  }
}

# IRSA role of the aws-ebs-csi-driver add-on
resource "aws_iam_role" "ebs_csi_driver" {
  name = coalesce(var.ebs_csi.name, "${var.name}-ebs-csi-driver")
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
            "${module.eks.oidc_provider}:sub" = [
              "system:serviceaccount:kube-system:ebs-csi-controller-sa",
              "system:serviceaccount:kube-system:ebs-csi-node-sa"
            ]
          }
        }
      }
    ]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_managed" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

# IRSA role of the aws-efs-csi-driver add-on
resource "aws_iam_role" "efs_csi_driver" {
  name = coalesce(var.efs_csi.name, "${var.name}-efs-csi-driver")
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
            "${module.eks.oidc_provider}:sub" = [
              "system:serviceaccount:kube-system:efs-csi-controller-sa",
              "system:serviceaccount:kube-system:efs-csi-node-sa"
            ]
          }
        }
      }
    ]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver_managed" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi_driver.name
}
