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

#EKS cluster
module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "~> 19.0"
  cluster_name                   = "test-cluster"
  cluster_version                = "1.27"
  vpc_id                         = data.aws_vpc.default.id
  subnet_ids                     = data.aws_subnets.subnets.ids
  control_plane_subnet_ids       = data.aws_subnets.subnets.ids
  cluster_endpoint_public_access = true
  eks_managed_node_group_defaults = {
    ami_type                   = "AL2_x86_64"
    instance_types             = ["c5.xlarge"]
    iam_role_attach_cni_policy = true
  }
  eks_managed_node_groups = {
    default_node_group = {
      use_custom_launch_template = false
      disk_size                  = 50
    }
  }
  tags = {
    env             = "test"
    app             = "complete"
    module          = "AWS efs-csi"
    "create by"     = data.aws_caller_identity.current.arn
    "creation date" = null_resource.timestamp.triggers["creation_date"]
  }
}

module "efs_csi" {
  source                        = "../../../efs-csi"
  csi_driver_image_pull_secrets = ""
  csi_driver_name               = "test"
  csi_driver_namespace          = "kube-system"
  csi_driver_node_selector      = {}
  csi_driver_repository         = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  csi_driver_version            = "2.3.0"
  oidc_url                      = module.eks.cluster_oidc_issuer_url
  oidc_arn                      = module.eks.oidc_provider_arn
  efs_csi_image                 = "amazon/aws-efs-csi-driver"
  efs_csi_tag                   = "v1.5.1"
  livenessprobe_image           = "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe"
  livenessprobe_tag             = "v2.9.0-eks-1-22-19"
  node_driver_registrar_image   = "public.ecr.aws/eks-distro/kubernetes-csi/node-driver-registrar"
  node_driver_registrar_tag     = "v2.7.0-eks-1-22-19"
  external_provisioner_image    = "public.ecr.aws/eks-distro/kubernetes-csi/external-provisioner"
  external_provisioner_tag      = "v3.4.0-eks-1-22-19"
  tags = {
    env             = "test"
    app             = "complete"
    module          = "AWS efs-csi"
    "create by"     = data.aws_caller_identity.current.arn
    "creation date" = null_resource.timestamp.triggers["creation_date"]
  }
  depends_on = [module.eks]
}
