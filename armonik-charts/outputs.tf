output "endpoints" {
  description = "URLs of ArmoniK, null until the load balancer of the ingress has an address."
  value = local.host == null ? null : {
    grpc    = "http://${local.host}:5001"
    gui     = "http://${local.host}:5000/admin/"
    grafana = "http://${local.host}:5000/grafana/"
    seq     = "http://${local.host}:5000/seq/"
  }
}

output "grafana_admin_password" {
  description = "Password of the Grafana user admin."
  value       = random_password.grafana_admin.result
  sensitive   = true
}
