
# # Tags
# variable "tags" {
#   description = "Tags for resource"
#   type        = any
#   default     = {}
# }

# Profile
variable "project_id" {
  description = "Project ID on which to create artifact registry (AR)"
  type        = string
}

# KMS to encrypt GCP repositories
variable "kms_key_name" {
  description = "KMS to encrypt GCP repositories"
  type        = string
  default     = ""
}

variable "zone" {
  description = "Zone of the project"
  type        = string
}

variable "region" {
  description = "Region of the project"
  type        = string
}

variable "credentials_file" {
  description = "Path to credential json file"
  type        = string
  validation {
    condition     = can(regex(".*\\.json", var.credentials_file))
    error_message = "The value of credentials_file need to be a json"
  }
}


# List of AR repositories to create
variable "repositories" {
  description = "List of AR repositories to create"
  type = list(object({
    artifact_repository_name = string
    description              = string
    format                   = string
    labels                   = optional(map(string))
    images                   = list(object({
                                name          = string
                                image         = string
                                tag           = string
                                }))
                              }))

  default = [
    {
      artifact_repository_name = "my-id-repository"
      description              = "my first artifact registry with TF"
      format                   = "docker"
      images                   = [
                    {
                      name  = "mongodb"
                      image = "mongo"
                      tag   = "4.4.11"
                    },
                    {
                      name  = "redis"
                      image = "redis"
                      tag   = "bullseye"
                    },
                    {
                      name  = "activemq"
                      image = "symptoma/activemq"
                      tag   = "5.16.3"
                    },
                    {
                      name  = "armonik-control-plane"
                      image = "dockerhubaneo/armonik_control"
                      tag   = "0.4.0"
                    },
                    {
                      name  = "armonik-polling-agent"
                      image = "dockerhubaneo/armonik_pollingagent"
                      tag   = "0.4.0"
                    },
                    {
                      name  = "armonik-worker"
                      image = "dockerhubaneo/armonik_worker_dll"
                      tag   = "0.1.2-SNAPSHOT.4.cfda5d1"
                    },
                    {
                      name  = "seq"
                      image = "datalust/seq"
                      tag   = "2021.4"
                    },
                    {
                      name  = "grafana"
                      image = "grafana/grafana"
                      tag   = "latest"
                    },
                    {
                      name  = "prometheus"
                      image = "prom/prometheus"
                      tag   = "latest"
                    },
                    {
                      name  = "cluster-autoscaler"
                      image = "k8s.gcr.io/autoscaling/cluster-autoscaler"
                      tag   = "v1.21.0"
                    },
                    {
                      name  = "fluent-bit"
                      image = "fluent/fluent-bit"
                      tag   = "1.3.11"
                    }
                  ]
    }
  ]
}
