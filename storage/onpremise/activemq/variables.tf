#########################################################################
#                              Metadata                                 #
#########################################################################
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}




#########################################################################
#                             Spec/container                            #
#########################################################################
variable "image" {
  description = "value"
  type        = string

}
variable "tag" {
  description = "value"
  type        = string
  default     = null
}

variable "security_context" {
  /*  type = object({
    fs_group        = optional(string)
    run_as_group    = optional(string)
    run_as_user     = optional(string)
    run_as_non_root = optional(string)
  })*/
  type        = list(any)
  description = "(Optional) SecurityContext holds pod-level security attributes and common container settings"
  default     = []
}

variable "min_ready_seconds" {
  description = "Field that specifies the minimum number of seconds for which a newly created Pod should be ready without any of its containers crashing, for it to be considered available"
  type        = number
  default     = null
}
#########################################################################
#                                 Spec                                  #
#########################################################################c
variable "progress_deadline_seconds" {
  description = "value"
  type        = number
  default     = 600
}
variable "active_deadline_seconds" {
  description = "value"
  type        = number
  default     = null
  #doit etre positive
}
variable "revision_history_limit" {
  description = "The number of revision hitory to keep."
  type        = number
  default     = 10
}
############################################
variable "termination_grace_period_seconds" {
  type        = number
  description = "Duration in seconds the pod needs to terminate gracefully"
  default     = null
}
variable "image_pull_secrets" {
  description = "value"
  type        = string

}
variable "strategy_update" {
  description = "Rolling update config params. Present only if strategy_update = RollingUpdate"
  type        = string
  default     = null

}
variable "node_name" {
  description = "value"
  type        = string
  default     = ""
}
variable "priority_class_name" {
  description = "Indicates the pod's priority. Requires an existing priority class name resource if not 'system-node-critical' and 'system-cluster-critical"
  type        = string
  default     = ""
}




variable "restart_policy" {
  type        = string
  description = "Restart policy for all containers within the pod. One of Always, OnFailure, Never"
  default     = "Always"
}
##############################################
variable "rolling_update" {
  description = "Rolling update config params. Present only if strategy_update = RollingUpdate"
  type        = object({ max_surge = optional(string), max_unavailable = optional(string) })
  default     = {}

}


variable "node_selector" {
  description = "Specify node selector for pod"
  type        = map(string)
  default     = {}

}

/*
variable "affinity" {
  description = "value"
}
*/
variable "toleration" {
  type = list(object({
    effect             = optional(string)
    key                = optional(string)
    operator           = optional(string)
    toleration_seconds = optional(string)
    value              = optional(string)
  }))
  description = "(Optional) Pod node tolerations"
  default     = []
}

#faut un local
