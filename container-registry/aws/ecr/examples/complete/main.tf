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
    },
    mongodb = {
      image = "mongo"
      tag   = "6.0.1"
    },
    armonik-control-plane = {
      image = "dockerhubaneo/armonik_control"
      tag   = "0.14.3"
    },
    armonik-polling-agent = {
      image = "dockerhubaneo/armonik_pollingagent"
      tag   = "0.14.3"
    },
    armonik-worker = {
      image = "dockerhubaneo/armonik_worker_dll"
      tag   = "0.12.1"
    },
    metrics-exporter = {
      image = "dockerhubaneo/armonik_control_metrics"
      tag   = "0.14.3"
    },
    partition-metrics-exporter = {
      image = "dockerhubaneo/armonik_control_partition_metrics"
      tag   = "0.14.3"
    },
    armonik-admin-app = {
      image = "dockerhubaneo/armonik_admin_app"
      tag   = "0.9.1"
    },
    armonik-admin-app-old = {
      image = "dockerhubaneo/armonik_admin_app"
      tag   = "0.8.0"
    },
    armonik-admin-api-old = {
      image = "dockerhubaneo/armonik_admin_api"
      tag   = "0.8.0"
    },
    mongosh = {
      image = "rtsp/mongosh"
      tag   = "1.7.1"
    },
    seq = {
      image = "datalust/seq"
      tag   = "2023.1"
    },
    seqcli = {
      image = "datalust/seqcli"
      tag   = "2023.1"
    },
    grafana = {
      image = "grafana/grafana"
      tag   = "9.3.6"
    },
    prometheus = {
      image = "prom/prometheus"
      tag   = "v2.42.0"
    },
    cluster-autoscaler = {
      image = "registry.k8s.io/autoscaling/cluster-autoscaler"
      tag   = "v1.23.0"
    },
    aws-node-termination-handler = {
      image = "public.ecr.aws/aws-ec2/aws-node-termination-handler"
      tag   = "v1.19.0"
    },
    metrics-server = {
      image = "registry.k8s.io/metrics-server/metrics-server"
      tag   = "v0.6.2"
    },
    fluent-bit = {
      image = "fluent/fluent-bit"
      tag   = "2.0.9"
    },
    node-exporter = {
      image = "prom/node-exporter"
      tag   = "v1.5.0"
    },
    nginx = {
      image = "nginxinc/nginx-unprivileged"
      tag   = "1.23.3"
    },
    keda = {
      image = "ghcr.io/kedacore/keda"
      tag   = "2.9.3"
    },
    keda-metrics-apiserver = {
      image = "ghcr.io/kedacore/keda-metrics-apiserver"
      tag   = "2.9.3"
    },
    aws-efs-csi-driver = {
      image = "amazon/aws-efs-csi-driver"
      tag   = "v1.5.1"
    },
    livenessprobe = {
      image = "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe"
      tag   = "v2.9.0-eks-1-22-19"
    },
    node-driver-registrar = {
      image = "public.ecr.aws/eks-distro/kubernetes-csi/node-driver-registrar"
      tag   = "v2.7.0-eks-1-22-19"
    },
    external-provisioner = {
      image = "public.ecr.aws/eks-distro/kubernetes-csi/external-provisioner"
      tag   = "v3.4.0-eks-1-22-19"
    }
  }
  new_repositories = {for k, v in local.repositories : "test/${k}" => v}
  lifecycle_policy = {
    rules = [
      {
        "rulePriority" : 1,
        "description" : "Expire images tagged with \"test\" older than 30 days",
        "selection" : {
          "tagStatus" : "tagged",
          "tagPrefixList" : ["test"],
          "countType" : "sinceImagePushed",
          "countUnit" : "days",
          "countNumber" : 30
        },
        "action" : {
          "type" : "expire"
        }
      },
      {
        "rulePriority" : 2,
        "description" : "Keep only one untagged image, expire all others",
        "selection" : {
          "tagStatus" : "untagged",
          "countType" : "imageCountMoreThan",
          "countNumber" : 1
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  }
}

# AWS ECR
module "complete_ecr" {
  source                 = "../../../ecr"
  aws_profile            = var.aws_profile
  kms_key_id             = null
  repositories           = local.new_repositories
  mutability             = "IMMUTABLE"
  scan_on_push           = true
  force_delete           = true
  encryption_type        = "AES256"
  only_pull_accounts     = ["125796369274"]
  push_and_pull_accounts = ["125796369274"]
  lifecycle_policy       = local.lifecycle_policy
  tags                   = {
    env             = "test"
    app             = "complete"
    module          = "AWS ECR"
    "create by"     = data.aws_caller_identity.current.arn
    "creation date" = null_resource.timestamp.triggers["creation_date"]
  }
}
