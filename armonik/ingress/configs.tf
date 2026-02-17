resource "kubernetes_config_map" "nginx" {
  count = var.nginx != null ? 1 : 0
  metadata {
    name      = "${var.nginx.name}-nginx"
    namespace = var.namespace
  }
  data = {
    "armonik.conf" = local.nginx_conf
  }
}

resource "kubernetes_config_map" "static" {
  count = var.nginx != null ? 1 : 0
  metadata {
    name      = "${var.nginx.name}-nginx-static"
    namespace = var.namespace
  }
  data = {
    for k, v in local.static :
    k => jsonencode(v)
  }
}

resource "local_file" "nginx_conf_file" {
  count           = var.nginx != null ? 1 : 0
  content         = local.nginx_conf
  filename        = "${path.root}/generated/configmaps/ingress/armonik.conf"
  file_permission = "0644"
}

resource "kubernetes_secret" "load_balancer_conf" {
  count = var.load_balancer != null ? 1 : 0
  metadata {
    name      = "load-balancer-clusters-conf"
    namespace = var.namespace
    labels    = var.load_balancer.labels
  }
  data = local.clusters_conf
}

resource "kubernetes_config_map" "load_balancer_conf" {
  count = can(coalesce(var.load_balancer.conf)) ? 1 : 0
  metadata {
    name      = "load-balancer-conf"
    namespace = var.namespace
    labels    = var.load_balancer.labels
  }
  data = local.global_conf
}

resource "kubernetes_config_map" "extra_conf" {
  count = can(coalesce(var.load_balancer.extra_env)) ? 1 : 0
  metadata {
    name      = "load-balancer-extra-conf"
    namespace = var.namespace
    labels    = var.load_balancer.labels
  }
  data = var.load_balancer.extra_env
}
