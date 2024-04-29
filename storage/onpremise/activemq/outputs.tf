# ActiveMQ
output "host" {
  description = "Host of ActiveMQ"
  value       = local.activemq_endpoints.ip
}

output "port" {
  description = "Port of ActiveMQ"
  value       = local.activemq_endpoints.port
}

output "url" {
  description = "URL of ActiveMQ"
  value       = local.activemq_url
}

output "web_url" {
  description = "Web URL of ActiveMQ"
  value       = local.activemq_web_url
}

output "user_certificate" {
  description = "User certificates of ActiveMQ"
  value = {
    secret    = kubernetes_secret.activemq_client_certificate.metadata[0].name
    data_keys = keys(kubernetes_secret.activemq_client_certificate.data)
  }
}

output "user_credentials" {
  description = "User credentials of ActiveMQ"
  value = {
    secret    = kubernetes_secret.activemq_user.metadata[0].name
    data_keys = keys(kubernetes_secret.activemq_user.data)
  }
}

output "endpoints" {
  description = "Endpoints of ActiveMQ"
  value = {
    secret    = kubernetes_secret.activemq.metadata[0].name
    data_keys = keys(kubernetes_secret.activemq.data)
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
  value = (merge({
    "Components__QueueAdaptorSettings__ClassName"           = local.adapter_class_name
    "Components__QueueAdaptorSettings__AdapterAbsolutePath" = local.adapter_absolute_path
    "Amqp__Host"                                            = local.activemq_endpoints.ip
    "Amqp__Port"                                            = local.activemq_endpoints.port
    "Amqp__Scheme"                                          = var.scheme
    "Amqp__CaPath"                                          = "${var.path}/chain.pem"
  }, var.extra_conf))

}

output "env_from_secret" {
  description = "Secrets to be set as environment variables"
  value = {
    secret     = kubernetes_secret.activemq_user_credentials.metadata[0].name
    credential = kubernetes_secret.activemq_user.metadata[0].name
  }
}

output "mount_secret" {
  description = "Secrets to be mounted as volumes"
  value = {
    "secret1" = {
      secret = kubernetes_secret.activemq
      path   = var.path
      mode   = "0600"
    },
    "secret2" = {
      secret = kubernetes_secret.activemq_user
      path   = "/cred"
      mode   = "0600"
    }
  }
}
