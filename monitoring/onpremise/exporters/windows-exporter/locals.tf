locals {
  tolerations = [
    for key, value in var.node_selector : {
      key      = key
      operator = "Equal"
      value    = value
      effect   = "NoSchedule"
    }
  ]

  node_selector = {
    for key, value in var.node_selector : key => value
  }
}
