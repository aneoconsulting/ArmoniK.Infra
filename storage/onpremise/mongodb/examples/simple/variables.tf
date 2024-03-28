variable "namespace" {
    description = "Namespace of ArmoniK resources"
    type = string
    default = "default"
}

variable "mongodb" {
    description = "Object containing the information to deploy properly MongoDB in K8s"
    type = object({
      image                 = string
      tag                   = string
      node_selector         = map(string)
      image_pull_secrets    = string
      replicas_number       = number 
    })
    default = {
        image = "mongo"
        tag = "latest"
        node_selector = {}
        image_pull_secrets = ""
        replicas_number = 1
    }
    validation {
      condition = var.mongodb.replicas_number > 0
      error_message = "The variable \"replicas_number\" must be greater than 0"
    }
}

variable "config_path" {
    description = "The kubernetes configuration file path you want to specify"
    type = string
    default = "~/.kube/config"
}