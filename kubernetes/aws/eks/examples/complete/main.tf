# Current account
data "aws_caller_identity" "current" {}

# this external provider is used to get date during the plan step.
data "external" "static_timestamp" {
  program = ["date", "+{ \"creation_date\": \"%Y/%m/%d %T\" }"]
}

# this resource is just used to prevent change of the creation_date during successive 'terraform apply'
resource "null_resource" "timestamp" {
  triggers = {
    creation_date = data.external.static_timestamp.result.creation_date
  }
  lifecycle {
    ignore_changes = [triggers]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# AWS EKS
module "eks" {
  source                                                   = "../.."
  name                                                     = "eks-complete-test"
  profile                                                  = "default"
  cluster_autoscaler_expander                              = "least-waste"
  cluster_autoscaler_image                                 = "registry.k8s.io/autoscaling/cluster-autoscaler"
  cluster_autoscaler_max_node_provision_time               = "15m0s"
  cluster_autoscaler_min_replica_count                     = 0
  cluster_autoscaler_namespace                             = "kube-system"
  cluster_autoscaler_repository                            = "https://kubernetes.github.io/autoscaler"
  cluster_autoscaler_scale_down_delay_after_add            = "2m"
  cluster_autoscaler_scale_down_delay_after_delete         = "0s"
  cluster_autoscaler_scale_down_delay_after_failure        = "3m"
  cluster_autoscaler_scale_down_enabled                    = true
  cluster_autoscaler_scale_down_non_empty_candidates_count = 30
  cluster_autoscaler_scale_down_unneeded_time              = "2m"
  cluster_autoscaler_scale_down_utilization_threshold      = 0.5
  cluster_autoscaler_scan_interval                         = "10s"
  cluster_autoscaler_skip_nodes_with_system_pods           = true
  cluster_autoscaler_tag                                   = "v1.32.0"
  cluster_autoscaler_version                               = "9.46.6"
  cluster_encryption_config                                = ""
  cluster_endpoint_private_access                          = false
  cluster_endpoint_public_access                           = true
  cluster_endpoint_public_access_cidrs                     = ["0.0.0.0/0"]
  cluster_log_kms_key_id                                   = ""
  cluster_log_retention_in_days                            = 30
  cluster_version                                          = "1.32"
  ebs_kms_key_id                                           = ""
  instance_refresh_image                                   = "public.ecr.aws/aws-ec2/aws-node-termination-handler"
  instance_refresh_namespace                               = "kube-system"
  instance_refresh_repository                              = "oci://public.ecr.aws/aws-ec2/helm"
  instance_refresh_tag                                     = "v1.25.1"
  instance_refresh_version                                 = "0.27.1"
  kubeconfig_file                                          = "generated/kubeconfig"
  vpc_id                                                   = data.aws_vpc.default.id
  vpc_pods_subnet_ids                                      = data.aws_subnets.subnets.ids
  vpc_private_subnet_ids                                   = data.aws_subnets.subnets.ids

  efs_csi = {
    image      = "public.ecr.aws/efs-csi-driver/amazon/aws-efs-csi-driver"
    tag        = "v2.1.8"
    repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
    version    = "3.1.9"
  }

  ebs_csi = {
    image      = "public.ecr.aws/ebs-csi-driver/aws-ebs-csi-driver"
    tag        = "v1.44.0"
    repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"
    version    = "2.44.0"
  }

  csi_liveness_probe = {
    image = "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe"
    tag   = "v2.15.0-eks-1-32-14"
  }

  csi_node_driver_registrar = {
    image = "public.ecr.aws/eks-distro/kubernetes-csi/node-driver-registrar"
    tag   = "v2.13.0-eks-1-32-14"
  }

  csi_external_provisioner = {
    image = "public.ecr.aws/eks-distro/kubernetes-csi/external-provisioner"
    tag   = "v5.2.0-eks-1-32-14"
  }

  eks_managed_node_groups = {
    test = {
      name                        = "workers"
      launch_template_description = "Node group for test"
      ami_type                    = "AL2_x86_64"
      instance_types              = ["c5.large"]
      capacity_type               = "SPOT"
      min_size                    = 0
      desired_size                = 1
      max_size                    = 1000
      labels = {
        service                        = "workers"
        "node.kubernetes.io/lifecycle" = "spot"
      }
      taints = {
        dedicated = {
          key    = "service"
          value  = "workers"
          effect = "NO_SCHEDULE"
        }
      }
      iam_role_use_name_prefix = false
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }

  self_managed_node_groups = {
    others = {
      name                        = "others"
      launch_template_description = "Node group for others"
      instance_type               = "c5.large"
      min_size                    = 0
      desired_size                = 1
      max_size                    = 5
      force_delete                = true
      force_delete_warm_pool      = true
      instance_market_options = {
        market_type = "spot"
      }
      bootstrap_extra_args     = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"
      iam_role_use_name_prefix = false
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
    others_mixed = {
      name                        = "others-mixed"
      launch_template_description = "Mixed On demand and SPOT instances for other pods"
      min_size                    = 0
      desired_size                = 1
      max_size                    = 5
      use_mixed_instances_policy  = true
      mixed_instances_policy = {
        on_demand_allocation_strategy            = "lowest-price"
        on_demand_base_capacity                  = 0
        on_demand_percentage_above_base_capacity = 20 # 20% On-Demand Instances, 80% Spot Instances
        spot_allocation_strategy                 = "price-capacity-optimized"
        spot_instance_pools                      = null
        spot_max_price                           = null
      }
      override = [
        {
          instance_type     = "c5.4xlarge"
          weighted_capacity = "1"
        },
        {
          instance_type     = "c5.2xlarge"
          weighted_capacity = "2"
        },
      ]
      iam_role_use_name_prefix = false
      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }

  # List of fargate profiles
  fargate_profiles = {}

  tags = {
    env             = "test"
    app             = "complete"
    module          = "AWS eks"
    "create by"     = data.aws_caller_identity.current.arn
    "creation date" = null_resource.timestamp.triggers["creation_date"]
  }
}
