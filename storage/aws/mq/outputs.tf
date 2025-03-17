# MQ
output "endpoint_url" {
  description = "AWS MQ endpoint urls"
  value       = aws_mq_broker.mq.engine_type == "ActiveMQ" ? aws_mq_broker.mq.instances[0].endpoints[1] : aws_mq_broker.mq.instances[0].endpoints[0]
}

output "endpoint_host" {
  description = "AWS MQ endpoint host"
  value       = aws_mq_broker.mq.engine_type == "ActiveMQ" ? trim(split(":", aws_mq_broker.mq.instances[0].endpoints[1])[1], "//") : trim(split(":", aws_mq_broker.mq.instances[0].endpoints[0])[1], "//")
}

output "endpoint_port" {
  description = "AWS MQ endpoint port"
  value       = aws_mq_broker.mq.engine_type == "ActiveMQ" ? tonumber(split(":", aws_mq_broker.mq.instances[0].endpoints[1])[2]) : tonumber(split(":", aws_mq_broker.mq.instances[0].endpoints[0])[2])
}


output "name" {
  description = "Name of MQ cluster"
  value       = aws_mq_broker.mq.broker_name
}

output "kms_key_id" {
  description = "ARN of KMS used for MQ"
  value       = aws_mq_broker.mq.encryption_options[0].kms_key_id
}

output "web_url" {
  description = "The URL of the broker's Amazon MQ Web Console"
  value       = aws_mq_broker.mq.instances[0].console_url
}

output "username" {
  description = "Username of Amazon MQ"
  value       = local.username
  sensitive   = true
}

output "password" {
  description = "Password of Amazon MQ"
  value       = local.password
  sensitive   = true
}

output "engine_type" {
  description = "Engine type"
  value       = var.engine_type
}

#new Outputs 
output "env" {
  description = "Elements to be set as environment variables"
  value = ({
    "Components__QueueStorage"                              = var.queue_storage_adapter
    "Components__QueueAdaptorSettings__ClassName"           = var.adapter_class_name
    "Components__QueueAdaptorSettings__AdapterAbsolutePath" = var.adapter_absolute_path
    "Amqp__Host"                                            = aws_mq_broker.mq.engine_type == "ActiveMQ" ? trim(split(":", aws_mq_broker.mq.instances[0].endpoints[1])[1], "//") : trim(split(":", aws_mq_broker.mq.instances[0].endpoints[0])[1], "//")
    "Amqp__Port"                                            = aws_mq_broker.mq.engine_type == "ActiveMQ" ? tonumber(split(":", aws_mq_broker.mq.instances[0].endpoints[1])[2]) : tonumber(split(":", aws_mq_broker.mq.instances[0].endpoints[0])[2])
    "Amqp__Scheme"                                          = var.scheme # Indicates also whether we use TLS or not
  })
}

output "env_secret" {
  description = "Secrets to be set as environment variables"
  value = [
    kubernetes_secret.activemq_user_credentials.metadata[0].name
  ]
}
