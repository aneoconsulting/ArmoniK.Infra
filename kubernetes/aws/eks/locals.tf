# Current account
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

# Available zones
data "aws_availability_zones" "available" {}

# Random string
resource "random_string" "random_resources" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

locals {
  region                                 = data.aws_region.current.name
  tags                                   = merge({ module = "eks-${var.name}" }, var.tags)
  iam_worker_autoscaling_policy_name     = "eks-worker-autoscaling-${var.name}"
  ima_aws_node_termination_handler_name  = "${var.name}-aws-node-termination-handler-${random_string.random_resources.result}"
  aws_node_termination_handler_asg_name  = "${var.name}-asg-termination"
  aws_node_termination_handler_spot_name = "${var.name}-spot-termination"
  kubeconfig_output_path                 = coalesce(var.kubeconfig_file, "${path.root}/generated/kubeconfig")

  # Node selector
  node_selector_keys   = keys(var.node_selector)
  node_selector_values = values(var.node_selector)
  node_selector = {
    nodeSelector = var.node_selector
  }
  tolerations = {
    tolerations = [
      for index in range(0, length(local.node_selector_keys)) : {
        key      = local.node_selector_keys[index]
        operator = "Equal"
        value    = local.node_selector_values[index]
        effect   = "NoSchedule"
      }
    ]
  }

  # EFS CSI
  efs_csi_name      = try(var.eks.efs_csi.name, "efs-csi-driver")
  oidc_arn          = module.eks.oidc_provider_arn
  oidc_url          = trimprefix(module.eks.cluster_oidc_issuer_url, "https://")
  efs_csi_namespace = try(var.eks.efs_csi.namespace, "kube-system")
  /*efs_csi_tolerations = [
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
      resources                = {}
      #      nodeSelector             = var.node_selector
      #      tolerations              = local.efs_csi_tolerations
      affinity = {}
      serviceAccount = {
        create      = false
        name        = kubernetes_service_account.efs_csi_driver_controller.metadata[0].name
        annotations = {}
      }
      healthPort           = 9909
      regionalStsEndpoints = false
    }
  }*/

  # Custom ENI
  subnets = {
    subnets = [
      for index, id in var.vpc.pods_subnet_ids : {
        subnet_id          = id
        az_name            = element(data.aws_availability_zones.available.names, index)
        security_group_ids = [module.eks.node_security_group_id]
      }
    ]
  }

  # Patch coredns
  patch_coredns_spec = {
    spec = {
      template = {
        spec = {
          nodeSelector = var.node_selector
          tolerations = [
            for index in range(0, length(local.node_selector_keys)) : {
              key      = local.node_selector_keys[index]
              operator = "Equal"
              value    = local.node_selector_values[index]
              effect   = "NoSchedule"
            }
          ]
        }
      }
    }
  }

  # List of EKS managed node groups
  eks_managed_node_groups = {
    for key, value in var.eks_managed_node_groups : key => merge(value, {
      name                       = can(coalesce(value.name)) ? "${try(value.name, "")}-${var.name}" : "${key}-${var.name}",
      enable_bootstrap_user_data = can(coalesce(value.ami_id))
    })
  }

  # List of self managed node groups
  self_managed_node_groups = {
    for key, value in var.self_managed_node_groups : key => merge(value, {
      name = can(coalesce(value.name)) ? "${try(value.name, "")}-${var.name}" : "${key}-${var.name}",
    })
  }

  # List of fargate profiles
  fargate_profiles = var.fargate_profiles

  # enable discovery of autoscaling groups by cluster-autoscaler
  autoscaling_group_tags = {
    "k8s.io/cluster-autoscaler/${var.name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"     = true
    "aws-node-termination-handler/managed"  = true
  }

  # List of effect for taints
  taint_effects = {
    NO_SCHEDULE        = "NoSchedule"
    NO_EXECUTE         = "NoExecute"
    PREFER_NO_SCHEDULE = "PreferNoSchedule"
  }

  # List of tags per eks managed group
  eks_autoscaling_group_tags = {
    for key, value in var.eks_managed_node_groups : key => merge(
      local.autoscaling_group_tags,
      { for k, v in try(value.labels, {}) : "k8s.io/cluster-autoscaler/node-template/label/${k}" => v },
      { for k, v in try(value.taints, {}) : "k8s.io/cluster-autoscaler/node-template/taint/${v.key}" => "${v.value}:${local.taint_effects[v.effect]}" }
    )
  }
}
