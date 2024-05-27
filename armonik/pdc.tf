locals {
  pdc_env = var.pod_deletion_cost != null ? merge({
    PrometheusUrl     = coalesce(var.pod_deletion_cost.prometheus_url, "http://prometheus.${var.namespace}.svc:9090/")
    MetricsName       = var.pod_deletion_cost.metrics_name
    Period            = var.pod_deletion_cost.period
    IgnoreYoungerThan = var.pod_deletion_cost.ignore_younger_than
    Concurrency       = var.pod_deletion_cost.concurrency
    Granularity       = var.pod_deletion_cost.granularity
  }, var.pod_deletion_cost.extra_conf) : {}
}

resource "kubernetes_service_account" "pod_deletion_cost" {
  count = var.pod_deletion_cost != null ? 1 : 0

  metadata {
    name      = var.pod_deletion_cost.name
    namespace = var.namespace
  }
}

resource "kubernetes_role" "pod_deletion_cost" {
  count = var.pod_deletion_cost != null ? 1 : 0

  metadata {
    name      = var.pod_deletion_cost.name
    namespace = var.namespace
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "patch"]
  }
}

resource "kubernetes_role_binding" "pod_deletion_cost" {
  count = var.pod_deletion_cost != null ? 1 : 0

  metadata {
    name      = var.pod_deletion_cost.name
    namespace = var.namespace
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.pod_deletion_cost[0].metadata[0].name
    namespace = kubernetes_service_account.pod_deletion_cost[0].metadata[0].namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.pod_deletion_cost[0].metadata[0].name
  }
}

# Pod Deletion Cost deployment
resource "kubernetes_deployment" "pod_deletion_cost" {
  count = var.pod_deletion_cost != null ? 1 : 0

  metadata {
    name      = var.pod_deletion_cost.name
    namespace = var.namespace
    labels = {
      app     = var.pod_deletion_cost.label_app
      service = "pod-deletion-cost"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app     = var.pod_deletion_cost.label_app
        service = "pod-deletion-cost"
      }
    }
    template {
      metadata {
        name      = var.pod_deletion_cost.name
        namespace = var.namespace
        labels = {
          app     = var.pod_deletion_cost.label_app
          service = "pod-deletion-cost"
        }
        annotations = var.pod_deletion_cost.annotations
      }
      spec {
        node_selector        = var.pod_deletion_cost.node_selector
        service_account_name = kubernetes_service_account.pod_deletion_cost[0].metadata[0].name
        dynamic "toleration" {
          for_each = var.pod_deletion_cost.node_selector
          content {
            key      = toleration.key
            operator = "Equal"
            value    = toleration.value
            effect   = "NoSchedule"
          }
        }
        dynamic "image_pull_secrets" {
          for_each = (var.pod_deletion_cost.image_pull_secrets != "" ? [1] : [])
          content {
            name = var.pod_deletion_cost.image_pull_secrets
          }
        }
        restart_policy = "Always" # Always, OnFailure, Never
        container {
          name              = var.pod_deletion_cost.name
          image             = can(coalesce(var.pod_deletion_cost.tag)) ? "${var.pod_deletion_cost.image}:${var.pod_deletion_cost.tag}" : var.pod_deletion_cost.image
          image_pull_policy = var.pod_deletion_cost.image_pull_policy

          resources {
            limits   = var.pod_deletion_cost.limits
            requests = var.pod_deletion_cost.requests
          }

          dynamic "env" {
            for_each = { for k, v in local.pdc_env : k => v if can(coalesce(v)) }
            content {
              name  = env.key
              value = env.value
            }
          }
        }
      }
    }
  }
}
