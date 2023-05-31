# AWS EC2 Instance Terraform Variables
# EC2 Instance Variables

# AWS EC2 Instance Type
variable "node_type" {
  description = "node_type"
  type        = string
  validation {
    condition     = contains(["master", "worker"], var.node_type)
    error_message = "Possible values for the parameter node_type are \"master\" or \"worker\"."
  }
}

# AWS EC2 Instance Key Pair
variable "master_public_ip" {
  description = "master_public_ip"
  type        = string
}

# AWS EC2 Private Instance Count
variable "master_private_ip" {
  description = "master_private_ip"
  type        = string
}

variable "public_ip" {
  description = "public_ip"
  type        = string
}

variable "user" {
  description = "user"
  type        = string
}

variable "tls_private_key_pem" {
  description = "tls_private_key_pem"
  type        = string
}

variable "kubeadm_token" {
  description = "kubeadm_token"
  type        = string
}

variable "worker_name" {
  description = "worker_name"
  type        = string
}
variable "cni_pluggin" {
  description = "cni plugin to be used. calico or flannel"
  type        = string
  default     = "calico"
  validation {
    condition     = contains(["calico", "flannel"], var.cni_pluggin)
    error_message = "Possible values for the parameter cni_pluggin are \"calico\" or \"flannel\"."
  }
}
variable "loadbalancer_plugin" {
  description = "loadbalancer plugin to be used. only metalLB for now"
  type        = string
  default     = ""
  validation {
    condition     = contains(["metalLB", ""], var.loadbalancer_plugin)
    error_message = "Possible values for the parameter loadbalancer_plugin are \"metalLB\" or empty \"\"."
  }
}

variable "workers" {
  description = "workers"
  type        = map(object({
    instance_count = number
    instance_type       = string
    label = optional(list(string), [])
    name = string
    public_dns = string
    taints = list(string)
  }))
}
#ex:
  # "worker-1" = {
  #   "instance_count" = 1
  #   "instance_type" = "m5.4xlarge"
  #   "labels" = tolist([
  #     "workers",
  #   ])
  #   "name" = "worker-1"
  #   "public_dns" = "ec2-3-8-5-81.eu-west-2.compute.amazonaws.com"
  #   "taints" = tolist([
  #     "workers",
  #   ])
  # }
