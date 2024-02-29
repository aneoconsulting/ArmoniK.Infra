#RabbitMQ
output "host" {
  description = "Host of RabbitMQ"
  value       = local.rabbitmq_endpoints.ip
}

output "port" {
  description = "Port of RabbitMQ"
  value       = local.rabbitmq_endpoints.port
}

output "url" {
  description = "URL of RabbitMQ"
  value       = local.rabbitmq_url
}

output "web_url" {
  description = "Web URL of RabbitMQ"
  value       = local.rabbitmq_web_url
}

output "user_certificate" {
  description = "User certificates of RabbitMQ"
  value = {
    secret    = kubernetes_secret.rabbitmq_client_certificate.metadata[0].name
    data_keys = keys(kubernetes_secret.rabbitmq_client_certificate.data)
  }
}

output "user_credentials" {
  description = "User credentials of RabbitMQ"
  value = {
    secret    = kubernetes_secret.rabbitmq_user.metadata[0].name
    data_keys = keys(kubernetes_secret.rabbitmq_user.data)
  }
}

output "endpoints" {
  description = "Endpoints of RabbitMQ"
  value = {
    secret    = kubernetes_secret.rabbitmq.metadata[0].name
    data_keys = keys(kubernetes_secret.rabbitmq.data)
  }
}

output "engine_type" {
  description = "Engine type"
  value       = local.engine_type
}

output "adapter_class_name" {
  description = "Class name for queue adapter"
  value       = local.adapter_class_name
}

output "adapter_absolute_path" {
  description = "Absolute path for the queue adapter"
  value       = local.adapter_absolute_path
}
