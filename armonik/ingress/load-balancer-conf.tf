resource "kubernetes_config_map" "load_balancer_conf" {
  count = var.load_balancer != null ? 1 : 0
  metadata {
    name      = "${local.prefix}load-balancer-conf"
    namespace = var.namespace
  }

  # Lots of verification on null values because Rust doesn't handle them well
  data = {
    "lb.yml" = jsonencode(merge({
      clusters = {
        for cluster, conf in var.clusters :
        cluster => merge({
          for key, value in conf :
          key => value if can(coalesce(value)) && !contains(["grafana_url", "seq_url", "s3_urls"], key)
          }, can(coalesce(conf.cert_pem)) && can(coalesce(conf.key_pem)) ? {
          cert_pem = conf.cert_pem != null ? "/cluster-certs/${cluster}.cert" : null
          key_pem  = conf.key_pem != null ? "/cluster-certs/${cluster}.key" : null
          } : {}, can(coalesce(conf.ca_cert)) ? {
          ca_cert = conf.ca_cert != null ? "/cluster-certs/${cluster}.ca" : null
          } : {}, {
          fallback = conf.fallback != null ? conf.fallback : cluster == var.default_cluster
        })
      }
      }, {
      for key, value in try(var.load_balancer.conf, {}) :
      key => value if can(coalesce(value))
    }))
  }
}

resource "kubernetes_config_map" "extra_env" {
  count = can(coalesce(var.load_balancer.extra_env)) ? 1 : 0
  metadata {
    name      = "${local.prefix}load-balancer-extra-env"
    namespace = var.namespace
    labels    = var.load_balancer.labels
  }
  data = var.load_balancer.extra_env
}

resource "local_file" "load_balancer_conf_file" {
  count           = var.load_balancer != null ? 1 : 0
  content         = kubernetes_config_map.load_balancer_conf[0].data["lb.yml"]
  filename        = "${path.root}/generated/secrets/load-balancer/conf.yml"
  file_permission = "0644"
}
