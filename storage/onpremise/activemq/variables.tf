#########################################################################
#                              Metadata                                 #
#########################################################################
variable "namespace" {
  description = "Namespace of ArmoniK storage resources"
  type        = string
}
variable "name" {
  description = "value"
  type        = string
  default     = "activemq"
}



#########################################################################
#                             Spec/container                            #
#########################################################################
variable "image" {
  description = "images of services"
  type        = string
  default     = "symptoma/activemq"

}
variable "tag" {
  description = "tag of images"
  type        = string
  default     = "5.17.0"
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
  type        = number
  description = "The maximum time in seconds for a deployment to make progress before it is considered to be failed"
  default     = 600
}
###
variable "active_deadline_seconds" {
  description = "Optional duration in seconds the pod may be active on the node relative to StartTime before the system will actively try to mark it failed and kill associated containers. Value must be a positive integer"
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
  default     = 20
}
variable "image_pull_secrets" {
  description = "(Optional) Specify list of pull secrets"
  type        = map(string)
  default     = {}
}

variable "strategy_update" {
  description = "(Optional) Type of deployment. Can be 'Recreate' or 'RollingUpdate'"
  type        = string
  default     = null


}
###
variable "node_name" {
  description = " (Optional) NodeName is a request to schedule this pod onto a specific node. If it is non-empty, the scheduler simply schedules this pod onto that node, assuming that it fits resource requirements"
  type        = string
  default     = null
}
####
variable "priority_class_name" {
  type        = string
  description = "Indicates the pod's priority. Requires an existing priority class name resource if not 'system-node-critical' and 'system-cluster-critical'"
  default     = ""
  validation {
    condition     = contains(["system-node-critical", "system-cluster-critical", ""], var.priority_class_name)
    error_message = "The valid values for the priority_class_name: \"system-node-critical\", \"system-cluster-critical\", \"\"."
  }
}





variable "restart_policy" {
  type        = string
  description = "Restart policy for all containers within the pod. One of Always, OnFailure, Never"
  default     = "Always"
  validation {
    condition     = contains(["Never", "Always", "OnFailure"], var.restart_policy)
    error_message = "The valid values for the priority_class_name: \"Never\", \"Always\", \"OnFailure\"."
  }
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
