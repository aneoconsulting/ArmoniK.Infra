locals {

  env          = try(merge([for element in var.conf_list : element.env]...), [])
  env_secret   = try(setunion([for element in var.conf_list : element.env_secret]...), {})
  mount_secret = try(merge([for element in var.conf_list : element.mount_secret]...), [])

}
