resource "helm_release" "kubecost" {
    name = "kubecost"
    namespace = var.namespace 
    repository = "https://kubecost.github.io/cost-analyzer/"
    chart = "cost-analyzer"

    set {
      name = "global.prometheus.fqdn"
      value = var.prometheus_fqdn 
    }

    set {
      name = "global.prometheus.enabled"
      value = false 
    }
}