output "metrics_server" {
  description = "Info about Metrics server"
  value = {
    chart_name = helm_release.metrics_server.name
  }
}
