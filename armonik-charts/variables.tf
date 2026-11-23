variable "namespace" {
  description = "Existing namespace of the armonik release, where the caller can create the Secrets the values read."
  type        = string
}

variable "operators_namespace" {
  description = "Namespace of the armonik-operators release, created by Helm."
  type        = string
  default     = "armonik-operators"
  nullable    = false
}

variable "chart_repository" {
  description = "Repository of the armonik and armonik-operators charts."
  type        = string
  default     = "oci://registry-1.docker.io/dockerhubaneo"
  nullable    = false
}

variable "chart_version" {
  description = "Version of the armonik and armonik-operators charts."
  type        = string
}

variable "versions" {
  description = "Image tags of ArmoniK (global.armonik.versions), null for the appVersion of the chart."
  type = object({
    core = optional(string)
    gui  = optional(string)
  })
  default  = {}
  nullable = false
}

variable "database_operators" {
  description = "Operators of in-cluster databases that armonik-operators installs: false when the storage is external."
  type = object({
    mongodb    = optional(bool, true)
    postgresql = optional(bool, true)
  })
  default  = {}
  nullable = false
}

variable "registries" {
  description = "Registry of the images of each upstream, such as the prefix of a pull-through cache: the image keeps its upstream path behind it."
  type = object({
    dockerhub = optional(string, "docker.io")
    ghcr      = optional(string, "ghcr.io")
    quay      = optional(string, "quay.io")
    k8s       = optional(string, "registry.k8s.io")
  })
  default  = {}
  nullable = false
}

variable "service_accounts" {
  description = "Kubernetes service accounts of the control and compute planes, to bind cloud roles to (Workload Identity, Pod Identity)."
  type = object({
    control_plane = optional(string, "armonik-control-plane")
    compute_plane = optional(string, "armonik-compute-plane")
  })
  default  = {}
  nullable = false
}

variable "partitions" {
  description = <<-EOT
    Partitions added to the chart's own (default, stream, htcmock, which scale to zero).
    * image: image without its tag, registry included.
    * cpu, memory: requests of the worker; its limits are cpu_limit (cpu when null) and memory.
    * max_replicas: KEDA scales the partition up to this many pods.
    * scale_to_zero: false keeps one pod when the partition is idle.
    * values: any other compute-plane value of the partition, YAML text, merged last.
  EOT
  type = map(object({
    image         = string
    tag           = string
    cpu           = optional(string, "1")
    cpu_limit     = optional(string)
    memory        = optional(string, "1Gi")
    max_replicas  = optional(number, 20)
    scale_to_zero = optional(bool, true)
    values        = optional(string, "{}")
  }))
  default  = {}
  nullable = false
  validation {
    condition     = alltrue([for name in keys(var.partitions) : can(regex("^[a-z0-9]+$", name))])
    error_message = "Partition names must be lowercase alphanumeric (KEDA metric names)."
  }
  validation {
    condition     = alltrue([for p in values(var.partitions) : can(keys(yamldecode(p.values)))])
    error_message = "The \"values\" of a partition must be a YAML mapping."
  }
}

variable "operators_values" {
  description = "Values documents (YAML text) of the armonik-operators chart, merged in order over those of the module."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "armonik_values" {
  description = "Values documents (YAML text) of the armonik chart, merged in order over those of the module and before the values of each partition."
  type        = list(string)
  default     = []
  nullable    = false
}

variable "timeout" {
  description = "Seconds Helm waits for each release to be ready: the first install creates nodes and pulls every image."
  type        = number
  default     = 1200
  nullable    = false
}
