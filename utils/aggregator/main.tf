locals {
  env                = var.materialize_configmap != null ? {} : merge([for element in var.conf_list : element.env]...)
  env_secret         = setunion([], [for element in var.conf_list : element.env_secret]...)
  mount_secret       = merge([for element in var.conf_list : element.mount_secret]...)
  env_from_secret    = merge([for element in var.conf_list : element.env_from_secret]...)
  env_configmap      = setunion(kubernetes_config_map.materialized[*].metadata[0].name, [for element in var.conf_list : element.env_configmap]...)
  env_from_configmap = merge([for element in var.conf_list : element.env_from_configmap]...)
  mount_configmap    = merge([for element in var.conf_list : element.mount_configmap]...)
}

resource "kubernetes_config_map" "materialized" {
  count = var.materialize_configmap != null ? 1 : 0
  metadata {
    name      = var.materialize_configmap.name
    namespace = var.materialize_configmap.namespace
  }

  data = merge([for element in var.conf_list : element.env]...)
}
