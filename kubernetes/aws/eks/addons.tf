locals {
  pod_identity = var.pod_identity

  # Service accounts of each workload role, trusted through both IRSA and EKS Pod Identity.
  workload_roles = {
    ebs_csi_driver = {
      namespace        = "kube-system"
      service_accounts = ["ebs-csi-controller-sa", "ebs-csi-node-sa"]
    }
    efs_csi_driver = {
      namespace        = "kube-system"
      service_accounts = ["efs-csi-controller-sa", "efs-csi-node-sa"]
    }
    cluster_autoscaler = {
      namespace        = var.cluster_autoscaler_namespace
      service_accounts = ["cluster-autoscaler"]
    }
  }

  # Drops null settings, nested resources fields included, so the add-on keeps its own defaults for them.
  ebs_csi_controller = { for k, v in {
    logLevel     = 2
    nodeSelector = var.node_selector
    tolerations  = local.tolerations.tolerations
    resources    = var.ebs_csi.controller_resources == null ? null : { for k, v in var.ebs_csi.controller_resources : k => v if v != null }
  } : k => v if v != null }

  efs_csi_controller = { for k, v in {
    logLevel                 = 2
    deleteAccessPointRootDir = false
    nodeSelector             = var.node_selector
    tolerations              = local.tolerations.tolerations
    resources                = var.efs_csi.controller_resources == null ? null : { for k, v in var.efs_csi.controller_resources : k => v if v != null }
  } : k => v if v != null }

  # One ENIConfig per pod subnet, named after its availability zone (ENI_CONFIG_LABEL_DEF).
  eni_configs = {
    for index, id in var.vpc_pods_subnet_ids : element(data.aws_availability_zones.available.names, index) => {
      id             = id
      securityGroups = [module.eks.node_security_group_id]
    }
  }

  # resolve_conflicts_on_create = OVERWRITE adopts the objects of a cluster that ran these components self-managed.
  addons = merge(local.pod_identity ? {
    eks-pod-identity-agent = {
      before_compute              = true
      resolve_conflicts_on_create = "OVERWRITE"
    }
    } : {}, {
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
      service_account_role_arn    = local.pod_identity ? null : aws_iam_role.ebs_csi_driver.arn
      pod_identity_association = local.pod_identity ? [{
        role_arn        = aws_iam_role.ebs_csi_driver.arn
        service_account = "ebs-csi-controller-sa"
      }] : null
      configuration_values = jsonencode({ controller = local.ebs_csi_controller })
    }
    aws-efs-csi-driver = {
      addon_version               = var.efs_csi.addon_version
      resolve_conflicts_on_create = "OVERWRITE"
      service_account_role_arn    = local.pod_identity ? null : aws_iam_role.efs_csi_driver.arn
      pod_identity_association = local.pod_identity ? [{
        role_arn        = aws_iam_role.efs_csi_driver.arn
        service_account = "efs-csi-controller-sa"
      }] : null
      configuration_values = jsonencode({ controller = local.efs_csi_controller })
    }
  })
}

# Cross-variable checks, cross-variable validation needing Terraform 1.9.
resource "null_resource" "inputs_guard" {
  lifecycle {
    # Custom networking without ENIConfigs leaves pods without IPs.
    precondition {
      condition     = !var.vpc_cni_custom_networking || length(var.vpc_pods_subnet_ids) > 0
      error_message = "vpc_cni_custom_networking requires vpc_pods_subnet_ids."
    }
    precondition {
      condition     = var.cluster_create_kms_key || can(coalesce(var.cluster_encryption_config))
      error_message = "cluster_create_kms_key = false requires cluster_encryption_config."
    }
    precondition {
      condition     = !local.ebs_kms_key_enabled || can(coalesce(var.ebs_kms_key_id))
      error_message = "ebs_kms_key_enabled = true requires ebs_kms_key_id."
    }
  }
}

# A warning only: clusters created with the module's key must keep it, whatever cluster_encryption_config says.
check "cluster_encryption_config_ignored" {
  assert {
    condition     = !var.cluster_create_kms_key || !can(coalesce(var.cluster_encryption_config))
    error_message = "cluster_encryption_config is ignored while cluster_create_kms_key is true: the EKS module encrypts the cluster's secrets with its own key."
  }
}

# Both mechanisms are always trusted, so switching pod_identity never breaks a running pod; the Pod Identity
# statement follows https://docs.aws.amazon.com/eks/latest/userguide/pod-id-role.html, also pinned to this cluster.
data "aws_iam_policy_document" "workload_trust" {
  for_each = local.workload_roles
  statement {
    sid     = "Irsa"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = [for sa in each.value.service_accounts : "system:serviceaccount:${each.value.namespace}:${sa}"]
    }
  }
  statement {
    sid     = "PodIdentity"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks-cluster-name"
      values   = [module.eks.cluster_name]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = [each.value.namespace]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = each.value.service_accounts
    }
  }
}

# Role of the aws-ebs-csi-driver add-on
resource "aws_iam_role" "ebs_csi_driver" {
  name               = coalesce(var.ebs_csi.name, "${var.name}-ebs-csi-driver")
  assume_role_policy = data.aws_iam_policy_document.workload_trust["ebs_csi_driver"].json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_managed" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

# Lets the driver create and attach volumes encrypted with ebs_kms_key_id (key id, alias or ARN).
data "aws_kms_key" "ebs" {
  count  = local.ebs_kms_key_enabled ? 1 : 0
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

# Role of the aws-efs-csi-driver add-on
resource "aws_iam_role" "efs_csi_driver" {
  name               = coalesce(var.efs_csi.name, "${var.name}-efs-csi-driver")
  assume_role_policy = data.aws_iam_policy_document.workload_trust["efs_csi_driver"].json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "efs_csi_driver_managed" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs_csi_driver.name
}
