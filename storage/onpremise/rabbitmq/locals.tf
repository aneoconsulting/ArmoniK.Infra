
locals {
  adapter_class_name    = var.adapter_class_name
  adapter_absolute_path = var.adapter_absolute_path
  engine_type           = "ActiveMQ"
  rabbitmq_dns          = "${var.name}.${var.namespace}.svc.cluster.local"
}
