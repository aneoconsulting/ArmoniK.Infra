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

module "efs" {
  source                 = "../../../efs"
  vpc_cidr_blocks        = [data.aws_vpc.default.cidr_block]
  vpc_cidr_block_private = []
  vpc_id                 = data.aws_vpc.default.id
  vpc_subnet_ids         = data.aws_subnets.subnets.ids
  name                   = "efs-test"
  transition_to_ia       = "AFTER_30_DAYS"
  throughput_mode        = "bursting"
  performance_mode       = "generalPurpose"
  #image_pull_secrets = ""
  #node_selector      = { service = "state-database" }
  #repository         = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  #version            = "2.3.0"
  #efs_csi_image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/aws-efs-csi-driver"
  #efs_csi_tag   = "v1.5.1"
  #livenessprobe_image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/livenessprobe"
  #livenessprobe_tag   = "v2.9.0-eks-1-22-19"
  #node_driver_registrar_image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/node-driver-registrar"
  #node_driver_registrar_image_tag   = "v2.7.0-eks-1-22-19"
  #external_provisioner_image = "125796369274.dkr.ecr.eu-west-3.amazonaws.com/external-provisioner"
  #external_provisioner_tag   = "v3.4.0-eks-1-22-19"
  tags = {
    env             = "test"
    app             = "complete"
    module          = "AWS efs"
    "create by"     = data.aws_caller_identity.current.arn
    "creation date" = null_resource.timestamp.triggers["creation_date"]
  }
}
