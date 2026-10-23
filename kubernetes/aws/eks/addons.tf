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
          AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = tostring(var.vpc_cni_custom_networking)
          ENI_CONFIG_LABEL_DEF               = "topology.kubernetes.io/zone"
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

# Custom networking without ENIConfigs leaves pods without IPs. Cross-variable validation needs Terraform 1.9.
resource "null_resource" "vpc_cni_custom_networking_guard" {
  lifecycle {
    precondition {
      condition     = !var.vpc_cni_custom_networking || length(var.vpc_pods_subnet_ids) > 0
      error_message = "vpc_cni_custom_networking requires vpc_pods_subnet_ids."
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

# Lets the driver create and attach volumes encrypted with ebs_kms_key_id (key id, alias or ARN).
data "aws_kms_key" "ebs" {
  count  = can(coalesce(var.ebs_kms_key_id)) ? 1 : 0
  region = var.region
  key_id = var.ebs_kms_key_id
}

data "aws_iam_policy_document" "ebs_csi_driver_kms" {
  count = length(data.aws_kms_key.ebs)
  statement {
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]
    resources = [data.aws_kms_key.ebs[0].arn]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = [true]
    }
  }
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [data.aws_kms_key.ebs[0].arn]
  }
}

resource "aws_iam_role_policy" "ebs_csi_driver_kms" {
  count  = length(data.aws_iam_policy_document.ebs_csi_driver_kms)
  name   = "kms"
  role   = aws_iam_role.ebs_csi_driver.id
  policy = data.aws_iam_policy_document.ebs_csi_driver_kms[0].json
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
