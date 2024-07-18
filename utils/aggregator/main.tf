locals {
  env                = merge([for element in var.conf_list : element.env]...)
  env_secret         = setunion([], [for element in var.conf_list : element.env_secret]...)
  mount_secret       = merge([for element in var.conf_list : element.mount_secret]...)
  env_from_secret    = merge([for element in var.conf_list : element.env_from_secret]...)
  env_configmap      = setunion([], [for element in var.conf_list : element.env_configmap]...)
  env_from_configmap = merge([for element in var.conf_list : element.env_from_configmap]...)
  mount_configmap    = merge([for element in var.conf_list : element.mount_configmap]...)
}
