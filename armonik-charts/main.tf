resource "random_password" "grafana_admin" {
  length  = 24
  special = false
}

resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "grafana-admin"
    namespace = var.namespace
  }

  data = {
    admin-user     = "admin"
    admin-password = random_password.grafana_admin.result
  }
}

# Installed once per cluster: their CRDs must exist before the armonik release renders its custom resources
resource "helm_release" "operators" {
  name             = "armonik-operators"
  namespace        = var.operators_namespace
  create_namespace = true
  repository       = var.chart_repository
  chart            = "armonik-operators"
  version          = var.chart_version
  values           = concat([yamlencode(local.operators_values)], var.operators_values)
  wait             = true
  timeout          = var.timeout
}

# Never wait_for_jobs: the init Jobs delete themselves one second after they end
resource "helm_release" "armonik" {
  name       = "armonik"
  namespace  = var.namespace
  repository = var.chart_repository
  chart      = "armonik"
  version    = var.chart_version
  values = concat(
    [yamlencode(local.armonik_values)],
    var.armonik_values,
    # A document of its own, so that Helm merges it deeply rather than replacing whole maps
    [yamlencode({ compute-plane = { partitions = { for name, p in var.partitions : name => yamldecode(p.values) } } })],
  )
  wait          = true
  wait_for_jobs = false
  timeout       = var.timeout

  depends_on = [helm_release.operators]
}

# The address of the load balancer is assigned during the install; depends_on defers the read after any change of
# the release
data "kubernetes_service_v1" "ingress" {
  metadata {
    name      = "armonik-ingress"
    namespace = var.namespace
  }

  depends_on = [helm_release.armonik]
}

locals {
  ingress = try(data.kubernetes_service_v1.ingress.status[0].load_balancer[0].ingress[0], null)
  host    = try(coalesce(local.ingress.ip, local.ingress.hostname), null)
}
