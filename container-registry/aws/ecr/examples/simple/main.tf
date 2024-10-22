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

locals {
  repositories = {
    armonik-polling-agent = {
      image = "dockerhubaneo/armonik_pollingagent"
      tag   = "0.14.3"
    }
  }
  new_repositories = { for k, v in local.repositories : "test/${k}" => v }
}

# AWS ECR
module "simple_ecr" {
  source       = "../../../ecr"
  repositories = local.new_repositories
  tags = {
    env             = "test"
    app             = "simple"
    module          = "AWS ECR"
    "create by"     = data.aws_caller_identity.current.arn
    "creation date" = null_resource.timestamp.triggers["creation_date"]
  }
}
