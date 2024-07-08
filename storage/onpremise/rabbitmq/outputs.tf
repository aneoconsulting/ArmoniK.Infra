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

#new Outputs 
output "env" {
  description = "Elements to be set as environment variables"
  value = ({
    "Components__QueueStorage"                              = var.queue_storage_adapter
    "Components__QueueAdaptorSettings__ClassName"           = local.adapter_class_name
    "Components__QueueAdaptorSettings__AdapterAbsolutePath" = local.adapter_absolute_path
    "Amqp__Host"                                            = local.rabbitmq_endpoints.ip
    "Amqp__Port"                                            = local.rabbitmq_endpoints.port
    "Amqp__Scheme"                                          = var.scheme
    "Amqp__CaPath"                                          = "${var.path}/chain.pem"
  })

}

output "env_secret" {
  description = "Secrets to be set as environment variables"
  value = [
    kubernetes_secret.rabbitmq_user_credentials.metadata[0].name
  ]
}

output "mount_secret" {
  description = "Secrets to be mounted as volumes"
  value = {
    "rabbitmq-secret1" = {
      secret = kubernetes_secret.rabbitmq.metadata[0].name
      path   = var.path
      mode   = "0644"
    }
  }
}
