# Based on the official aws-node-termination-handler setup guide at https://github.com/aws/aws-node-termination-handler#infrastructure-setup
# Instance Metadata Service mode: a pod per node watches IMDS and drains the node, no AWS API call nor IAM role involved.
resource "helm_release" "aws_node_termination_handler" {
  name             = "aws-node-termination-handler"
  namespace        = var.instance_refresh_namespace
  chart            = "aws-node-termination-handler"
  repository       = var.instance_refresh_repository
  version          = var.instance_refresh_version
  create_namespace = true

  set {
    name  = "awsRegion"
    value = local.region
  }
  set {
    name  = "logLevel"
    value = "debug"
  }
  set {
    name  = "enableSpotInterruptionDraining"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-node-termination-handler"
  }
  set {
    name  = "image.repository"
    value = var.instance_refresh_image
  }
  set {
    name  = "image.tag"
    value = var.instance_refresh_tag
  }
  # EKS drains the nodes of managed node groups itself, so the handler only runs on self-managed nodes.
  values = [yamlencode({
    daemonsetAffinity = {
      nodeAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = {
          nodeSelectorTerms = [{
            matchExpressions = [
              {
                key      = "eks.amazonaws.com/compute-type"
                operator = "NotIn"
                values   = ["fargate"]
              },
              {
                key      = "eks.amazonaws.com/nodegroup"
                operator = "DoesNotExist"
              },
            ]
          }]
        }
      }
    }
  })]
  depends_on = [
    module.eks,
    null_resource.update_kubeconfig
  ]
}

# Holds a terminating self-managed node for heartbeat_timeout, the window in which the handler drains it on the
# ASG target lifecycle state; IMDS mode never completes the action, so termination always waits the full timeout.
# Creating the lifecycle-hook outside of the ASG resource's `initial_lifecycle_hook`
# ensures that node termination does not require the lifecycle action to be completed,
# and thus allows the ASG to be destroyed cleanly.
resource "aws_autoscaling_lifecycle_hook" "aws_node_termination_handler" {
  for_each               = module.eks.self_managed_node_groups
  region                 = var.region
  name                   = "aws-node-termination-handler"
  autoscaling_group_name = each.value.autoscaling_group_name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  heartbeat_timeout      = 300
  default_result         = "CONTINUE"
}
