data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
  source          = "../.."
  cluster_autoscaler_expander = ""
  cluster_autoscaler_image = ""
  cluster_autoscaler_max_node_provision_time = ""
  cluster_autoscaler_min_replica_count = 0
  cluster_autoscaler_namespace = ""
  cluster_autoscaler_repository = ""
  cluster_autoscaler_scale_down_delay_after_add = ""
  cluster_autoscaler_scale_down_delay_after_delete = ""
  cluster_autoscaler_scale_down_delay_after_failure = ""
  cluster_autoscaler_scale_down_enabled = false
  cluster_autoscaler_scale_down_non_empty_candidates_count = 0
  cluster_autoscaler_scale_down_unneeded_time = ""
  cluster_autoscaler_scale_down_utilization_threshold = 0
  cluster_autoscaler_scan_interval = ""
  cluster_autoscaler_skip_nodes_with_system_pods = false
  cluster_autoscaler_tag = ""
  cluster_autoscaler_version = ""
  cluster_encryption_config = ""
  cluster_endpoint_private_access = false
  cluster_endpoint_private_access_cidrs = []
  cluster_endpoint_private_access_sg = []
  cluster_endpoint_public_access = false
  cluster_endpoint_public_access_cidrs = []
  cluster_log_kms_key_id = ""
  cluster_log_retention_in_days = 0
  cluster_version = ""
  ebs_kms_key_id = ""
  instance_refresh_image = ""
  instance_refresh_namespace = ""
  instance_refresh_repository = ""
  instance_refresh_tag = ""
  instance_refresh_version = ""
  kubeconfig_file = ""
  map_roles_groups = []
  map_roles_rolearn = ""
  map_roles_username = ""
  map_users_groups = []
  map_users_userarn = ""
  map_users_username = ""
  profile = ""
  vpc_id = ""
  vpc_pods_subnet_ids = []
  vpc_private_subnet_ids = []
}
