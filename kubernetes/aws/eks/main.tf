# Current account
data "aws_caller_identity" "current" {}

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

  # Custom ENI
  subnets = {
    subnets = [
      for index, id in var.vpc_pods_subnet_ids : {
        subnet_id          = id
        az_name            = element(data.aws_availability_zones.available.names, index)
        security_group_ids = [module.eks.node_security_group_id]
      }
    ]
  }

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


module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.21.0"
  create          = true
  cluster_name    = var.name
  cluster_version = var.cluster_version

  # VPC
  subnet_ids = var.vpc_private_subnet_ids
  vpc_id     = var.vpc_id

  create_aws_auth_configmap = !(can(coalesce(var.eks_managed_node_groups)) && can(coalesce(var.fargate_profiles)))
  # Needed to add self managed node group configuration.
  # => kubectl get cm aws-auth -n kube-system -o yaml
  manage_aws_auth_configmap = true

  # Private cluster
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  # Public cluster
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Cluster parameters
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_kms_key_id        = var.cluster_log_kms_key_id
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_in_days
  create_cluster_security_group          = true

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

  cluster_encryption_config = {
    provider_key_arn = var.cluster_encryption_config
    resources        = ["secrets"]
  }

  # Tags
  tags         = local.tags
  cluster_tags = local.tags

  # IAM
  # used to allow other users to interact with our cluster
  aws_auth_roles = var.map_roles_groups
  aws_auth_users = concat([
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.arn}:user/admin"
      username = "admin"
      groups   = ["system:masters", "system:bootstrappers", "system:nodes"]
    }
  ], var.map_users_groups)

  # List of EKS managed node groups
  eks_managed_node_group_defaults = {
    enable_monitoring = true
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 2
      instance_metadata_tags      = "disabled"
    }
    # The sysctls fs.inotify.max_user_instances defines user limits on the number of inotify resources.
    # In the context of a Kubernetes cluster, if these limits are reached, you may experience processes
    # failing with error messages related to the limits, and it would exhibit as failing Pods with inotify
    # related errors in the Pod logs.
    post_bootstrap_user_data = <<-EOT
        echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
      EOT
  }

  # List of self managed node groups
  self_managed_node_group_defaults = {
    enable_monitoring      = true
    tags                   = local.tags
    autoscaling_group_tags = local.autoscaling_group_tags
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 2
      instance_metadata_tags      = "disabled"
    }
    # The sysctls fs.inotify.max_user_instances defines user limits on the number of inotify resources.
    # In the context of a Kubernetes cluster, if these limits are reached, you may experience processes
    # failing with error messages related to the limits, and it would exhibit as failing Pods with inotify
    # related errors in the Pod logs.
    post_bootstrap_user_data = <<-EOT
        echo fs.inotify.max_user_instances=8192 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
      EOT
  }

  # List of fargate profiles
  fargate_profile_defaults = {
    tags = local.tags
  }

  # Worker groups
  # module input from doc : https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest?tab=inputs#optional-inputs
  # variables from module code : https://github.dev/terraform-aws-modules/terraform-aws-eks/tree/v19.10.0
  # sample usages : https://github.com/Jitsusama/example-terraform-eks-mixed-os-cluster/blob/main/cluster.tf#L91
  #                 https://github.dev/terraform-aws-modules/terraform-aws-eks/tree/v19.10.0
  eks_managed_node_groups  = local.eks_managed_node_groups
  self_managed_node_groups = local.self_managed_node_groups
  fargate_profiles         = local.fargate_profiles
}
