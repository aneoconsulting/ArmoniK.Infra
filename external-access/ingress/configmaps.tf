resource "kubernetes_config_map" "ingress" {
  count = (var.ingress != null ? 1 : 0)
  metadata {
    name      = "${var.ingress.name}-nginx"
    namespace = var.namespace
  }
  data = {
    "armonik.conf" = local.nginx_conf
  }
}

resource "kubernetes_config_map" "static" {
  count = (var.ingress != null ? 1 : 0)
  metadata {
    name      = "${var.ingress.name}-nginx-static"
    namespace = var.namespace
  }
  data = {
    for k, v in local.static :
    k => jsonencode(v)
  }
}

resource "local_file" "ingress_conf_file" {
  count           = (var.ingress != null ? 1 : 0)
  content         = local.nginx_conf
  filename        = "${path.root}/generated/configmaps/ingress/armonik.conf"
  file_permission = "0644"
}
