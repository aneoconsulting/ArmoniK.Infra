output "host" {
  description = "DNS name of the instance in the client network"
  value       = module.simple_cloudsql.host
}
