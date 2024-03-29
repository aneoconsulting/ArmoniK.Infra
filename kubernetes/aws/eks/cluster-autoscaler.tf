# A component that automatically adjusts the size of a Kubernetes Cluster so that all pods have a place to run and there are no unneeded nodes
resource "helm_release" "cluster_autoscaler" {
  name       = "armonik"
  namespace  = var.cluster_autoscaler_namespace
  chart      = "cluster-autoscaler"
  repository = var.cluster_autoscaler_repository
  version    = var.cluster_autoscaler_version

  # Method 1 - Using Autodiscovery
  set {
    name  = "autoDiscovery.clusterName"
    value = var.name
  }
  set {
    name  = "awsRegion"
    value = local.region
  }
  set {
    name  = "cloudProvider"
    value = "aws"
  }
  set {
    name  = "image.repository"
    value = var.cluster_autoscaler_image
  }
  set {
    name  = "image.tag"
    value = var.cluster_autoscaler_tag
  }
  set {
    name  = "extraArgs.logtostderr"
    value = true
  }
  set {
    name  = "extraArgs.stderrthreshold"
    value = "Info"
  }
  set {
    name  = "extraArgs.v"
    value = "4"
  }
  set {
    name  = "extraArgs.aws-use-static-instance-list"
    value = true
  }
  set {
    name  = "extraArgs.expander"
    value = var.cluster_autoscaler_expander
  }
  set {
    name  = "extraArgs.scale-down-enabled"
    value = var.cluster_autoscaler_scale_down_enabled
  }
  set {
    name  = "extraArgs.min-replica-count"
    value = var.cluster_autoscaler_min_replica_count
  }
  set {
    name  = "extraArgs.scale-down-utilization-threshold"
    value = var.cluster_autoscaler_scale_down_utilization_threshold
  }
  set {
    name  = "extraArgs.scale-down-non-empty-candidates-count"
    value = var.cluster_autoscaler_scale_down_non_empty_candidates_count
  }
  set {
    name  = "extraArgs.max-node-provision-time"
    value = var.cluster_autoscaler_max_node_provision_time
  }
  set {
    name  = "extraArgs.scan-interval"
    value = var.cluster_autoscaler_scan_interval
  }
  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = var.cluster_autoscaler_scale_down_delay_after_add
  }
  set {
    name  = "extraArgs.scale-down-delay-after-delete"
    value = var.cluster_autoscaler_scale_down_delay_after_delete
  }
  set {
    name  = "extraArgs.scale-down-delay-after-failure"
    value = var.cluster_autoscaler_scale_down_delay_after_failure
  }
  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = var.cluster_autoscaler_scale_down_unneeded_time
  }
  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = var.cluster_autoscaler_skip_nodes_with_system_pods
  }
  set {
    name  = "resources.limits.cpu"
    value = "3000m"
  }
  set {
    name  = "resources.limits.memory"
    value = "3000Mi"
  }
  set {
    name  = "resources.requests.cpu"
    value = "1000m"
  }
  set {
    name  = "resources.requests.memory"
    value = "1000Mi"
  }

  # Method 2 - Specifying groups manually
  # Example for an ASG
  /*set {
    name  = "autoscalingGroups[0].name"
    value = "<your-asg-name>"
  }
  set {
    name  = "autoscalingGroups[0].maxSize"
    value = "10"
  }
  set {
    name  = "autoscalingGroups[0].minSize"
    value = "1"
  }*/

  values = [
    yamlencode(local.node_selector),
    yamlencode(local.tolerations)
  ]
  depends_on = [
    module.eks,
    null_resource.update_kubeconfig
  ]
}

# Workers Auto Scaling policy
data "aws_iam_policy_document" "worker_autoscaling" {
  statement {
    sid    = "eksWorkerAutoscalingAll"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
    ]
    resources = ["*"]
  }
  statement {
    sid    = "eksWorkerAutoscalingOwn"
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeImages",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "autoscaling:UpdateAutoScalingGroup",
      "eks:DescribeNodegroup"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "worker_autoscaling" {
  name_prefix = local.iam_worker_autoscaling_policy_name
  description = "EKS worker node autoscaling policy for cluster ${module.eks.cluster_name}"
  policy      = data.aws_iam_policy_document.worker_autoscaling.json
  tags        = local.tags
}

resource "aws_iam_policy_attachment" "workers_autoscaling" {
  name = "eks-worker-node-autoscaling-${module.eks.cluster_name}"
  roles = concat(
    values(module.eks.eks_managed_node_groups)[*].iam_role_name,
    values(module.eks.self_managed_node_groups)[*].iam_role_name,
  values(module.eks.fargate_profiles)[*].iam_role_name)
  policy_arn = aws_iam_policy.worker_autoscaling.arn
}
