variable "master" {
  description = "The master node to be deployed."
  type = object({
    name                     = string
    public_dns               = string # it can be private if you are inside the destination network
    private_dns              = string
    tls_private_key_pem_file = string
  })
}

variable "workers" {
  description = "The worker nodes to be deployed."
  type = map(object({
    instance_count = optional(number, 1)
    label          = optional(list(string), [])
    name           = string
    public_dns     = string
    taints         = optional(list(string), [])
  }))
}

variable "user" {
  description = "user used to execute docker + kubernetes scripts. must be updated accordingly with the linux image used"
  type        = string
}
