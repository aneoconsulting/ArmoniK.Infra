output "username" {
  description = "AWS Amazon MQ username"
  sensitive   = true
  value       = module.activemq.username
}

output "password" {
  description = "AWS Amazon MQ password"
  sensitive   = true
  value       = module.activemq.password
}

output "name" {
  description = "Name of Amazon MQ cluster"
  value       = module.activemq.name
}

output "activemq_endpoint_url" {
  description = "AWS Amazon MQ endpoint urls"
  value       = module.activemq.endpoint_url

}

output "activemq_endpoint_host" {
  description = "AWS Amazon MQ endpoint host"
  value       = module.activemq.endpoint_host
}

output "activemq_endpoint_port" {
  description = "AWS Amazon MQ endpoint port"
  value       = module.activemq.endpoint_port

}

output "engine_type" {
  description = "Engine type"
  value       = module.activemq.engine_type
}

output "web_url" {
  description = "Web URL for Amazon Amazon MQ"
  value       = module.activemq.web_url
}
