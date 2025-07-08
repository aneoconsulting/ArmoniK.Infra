# EFS Container Storage Interface (CSI) Driver
variable "csi_driver_name" {
  description = "CSI driver name"
  type        = string
}

variable "csi_driver_namespace" {
  description = "CSI driver namespace "
  type        = string
}

variable "csi_driver_image_pull_secrets" {
  description = "CSI driver image pull secrets"
  type        = string
}


variable "csi_driver_node_selector" {
  description = "CSI driver node selector"
  type        = any
}

variable "csi_driver_repository" {
  description = "CSI driver repository"
  type        = string
}

variable "csi_driver_version" {
  description = "CSI driver version"
  type        = string
}

variable "efs_csi_image" {
  description = "EFS CSI image"
  type        = string
}

variable "efs_csi_tag" {
  description = "EFS CSI tag"
  type        = string
}

variable "livenessprobe_image" {
  description = "Livenessprobe image"
  type        = string
}

variable "livenessprobe_tag" {
  description = "Livenessporbe tag"
  type        = string
}

variable "node_driver_registrar_image" {
  description = "Node driver registrar image"
  type        = string
}

variable "node_driver_registrar_tag" {
  description = "Node driver registrar tag"
  type        = string
}

variable "external_provisioner_image" {
  description = "External provisioner image"
  type        = string
}

variable "external_provisioner_tag" {
  description = "External provisioner tag"
  type        = string
}

# EKS issuer
variable "oidc_arn" {
  description = "Cluster oidc arn"
  type        = string
}

variable "oidc_url" {
  description = "Cluster oidc url"
  type        = string
}

# Tags
variable "tags" {
  description = "Tags for EFS CSI driver"
  type        = map(string)
}
