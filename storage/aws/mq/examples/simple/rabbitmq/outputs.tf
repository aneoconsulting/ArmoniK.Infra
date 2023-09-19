output "username" {
  description = "AWS Amazon MQ username"
  sensitive   = true
  value       = module.rabbitmq.username
}

output "password" {
  description = "AWS Amazon MQ password"
  sensitive   = true
  value       = module.rabbitmq.password
}

output "name" {
  description = "Name of Amazon MQ cluster"
  value       = module.rabbitmq.name
}

output "rabbitmq_endpoint_url" {
  description = "AWS Amazon MQ endpoint urls"
  value       = module.rabbitmq.endpoint_url

}

output "rabbitmq_endpoint_host" {
  description = "AWS Amazon MQ endpoint host"
  value       = module.rabbitmq.endpoint_host
}

output "rabbitmq_endpoint_port" {
  description = "AWS Amazon MQ endpoint port"
  value       = module.rabbitmq.endpoint_port

}

output "engine_type" {
  description = "Engine type"
  value       = module.rabbitmq.engine_type
}

output "web_url" {
  description = "Web URL for Amazon Rabbitmq"
  value       = module.rabbitmq.web_url
}
