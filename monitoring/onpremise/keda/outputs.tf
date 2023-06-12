output "keda" {
  description = "Info about KEDA"
  value = {
    chart_name = helm_release.keda.name
  }
}
