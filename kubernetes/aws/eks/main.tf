data "aws_region" "current" {
  region = var.region
}

data "aws_partition" "current" {}

# Available zones
data "aws_availability_zones" "available" {
  region = var.region
}

locals {
  region                 = data.aws_region.current.region
  tags                   = merge({ module = "eks-${var.name}" }, var.tags)
  kubeconfig_output_path = coalesce(var.kubeconfig_file, "${path.root}/generated/kubeconfig")

  # Counts cannot depend on a key only known after apply, hence the explicit bool; unset, it follows the key.
  ebs_kms_key_enabled = var.ebs_kms_key_enabled != null ? var.ebs_kms_key_enabled : can(coalesce(var.ebs_kms_key_id))

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

  # Node group defaults; the upstream module has no *_defaults inputs, so they are merged here, the node group winning.
  # A hop limit of 1 keeps pods off the node role; workloads get AWS credentials through IRSA.
  node_metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }
  # The sysctls fs.inotify.max_user_instances defines user limits on the number of inotify resources.
  # In the context of a Kubernetes cluster, if these limits are reached, you may experience processes
  # failing with error messages related to the limits, and it would exhibit as failing Pods with inotify
  # related errors in the Pod logs.
  # Runs before bootstrap: AL2 nodes take it as pre_bootstrap_user_data, AL2023 nodes (the default ami_type) as a
  # nodeadm cloud-init part; the EKS module drops post-bootstrap user data on managed node groups and on AL2023.
  # Windows and Bottlerocket nodes cannot run a bash script, so they get none.
  node_sysctl_user_data = <<-EOT
      #!/bin/bash
      echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
    EOT
  node_sysctl_nodeadm_part = {
    content_type = "text/x-shellscript"
    content      = local.node_sysctl_user_data
  }

  # List of EKS managed node groups
  eks_managed_node_groups = {
    for key, value in var.eks_managed_node_groups : key => merge({
      enable_monitoring       = true
      metadata_options        = local.node_metadata_options
      pre_bootstrap_user_data = startswith(coalesce(try(value.ami_type, null), "AL2023_"), "AL2_") ? local.node_sysctl_user_data : null
      }, value, {
      name                       = can(coalesce(value.name)) ? "${try(value.name, "")}-${var.name}" : "${key}-${var.name}",
      enable_bootstrap_user_data = can(coalesce(value.ami_id))
      vpc_security_group_ids     = [module.eks.node_security_group_id]
      cloudinit_pre_nodeadm = concat(
        startswith(coalesce(try(value.ami_type, null), "AL2023_"), "AL2023_") ? [local.node_sysctl_nodeadm_part] : [],
        try(value.cloudinit_pre_nodeadm, null) == null ? [] : value.cloudinit_pre_nodeadm,
      )
    })
  }

  # List of self managed node groups
  self_managed_node_groups = {
    for key, value in var.self_managed_node_groups : key => merge({
      enable_monitoring       = true
      tags                    = local.tags
      autoscaling_group_tags  = local.autoscaling_group_tags
      metadata_options        = local.node_metadata_options
      pre_bootstrap_user_data = startswith(coalesce(try(value.ami_type, null), "AL2023_"), "AL2_") ? local.node_sysctl_user_data : null
      }, value, {
      name = can(coalesce(value.name)) ? "${try(value.name, "")}-${var.name}" : "${key}-${var.name}",
      cloudinit_pre_nodeadm = concat(
        startswith(coalesce(try(value.ami_type, null), "AL2023_"), "AL2023_") ? [local.node_sysctl_nodeadm_part] : [],
        try(value.cloudinit_pre_nodeadm, null) == null ? [] : value.cloudinit_pre_nodeadm,
      )
    })
  }

  # List of fargate profiles
  fargate_profiles = {
    for key, value in var.fargate_profiles : key => merge({ tags = local.tags }, value)
  }

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


module "eks" {
  source              = "terraform-aws-modules/eks/aws"
  version             = "21.29.0"
  create              = true
  region              = var.region
  name                = var.name
  kubernetes_version  = var.cluster_version
  deletion_protection = var.cluster_deletion_protection

  # If you want to maintain the current default behavior of v19.x
  kms_key_enable_default_policy   = false
  kms_key_rotation_period_in_days = var.cluster_kms_key_rotation_period_in_days

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  # VPC
  subnet_ids = var.vpc_private_subnet_ids
  vpc_id     = var.vpc_id

  # Private cluster
  endpoint_private_access = var.cluster_endpoint_private_access

  # Public cluster
  endpoint_public_access       = var.cluster_endpoint_public_access
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Control plane
  control_plane_scaling_config   = var.cluster_control_plane_scaling_config
  control_plane_egress_mode      = var.cluster_control_plane_egress_mode
  kube_api_server_config         = var.cluster_kube_api_server_config
  kube_controller_manager_config = var.cluster_kube_controller_manager_config
  kube_scheduler_config          = var.cluster_kube_scheduler_config

  # Cluster parameters
  enabled_log_types                      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_kms_key_id        = var.cluster_log_kms_key_id
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_in_days
  create_security_group                  = true

  # The VPC resource controller assigns the IPs of Windows pods with the cluster role
  # (https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html).
  iam_role_additional_policies = {
    AmazonEKSVPCResourceController = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node port 80 ingress"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      type        = "ingress"
      self        = true
    }
  }

  additional_security_group_ids = [module.eks.node_security_group_id]

  create_kms_key = var.cluster_create_kms_key
  encryption_config = {
    provider_key_arn = var.cluster_create_kms_key ? null : var.cluster_encryption_config
    resources        = ["secrets"]
  }

  # Tags
  tags         = local.tags
  cluster_tags = local.tags

  addons = local.addons

  # Worker groups
  # module input from doc : https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest?tab=inputs#optional-inputs
  eks_managed_node_groups  = local.eks_managed_node_groups
  self_managed_node_groups = local.self_managed_node_groups
  fargate_profiles         = local.fargate_profiles
}
