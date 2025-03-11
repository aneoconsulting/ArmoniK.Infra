locals {
  # ActiveMQ node selector
  node_selector_keys    = keys(var.activemq.node_selector)
  node_selector_values  = values(var.activemq.node_selector)
  adapter_class_name    = var.adapter_class_name
  adapter_absolute_path = var.adapter_absolute_path
  engine_type           = "ActiveMQ"
  activemq_dns          = "${var.name}.${var.namespace}.svc.cluster.local"

}
