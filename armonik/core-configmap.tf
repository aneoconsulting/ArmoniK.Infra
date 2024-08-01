# configmap with all the variables
# resource "kubernetes_config_map" "core_config" {
#   metadata {
#     name      = "core-configmap"
#     namespace = var.namespace
#   }
#   data = merge({
#     Authenticator__RequireAuthentication = local.authentication_require_authentication
#     Authenticator__RequireAuthorization  = local.authentication_require_authorization
#   }, var.extra_conf.core)
# }

module "core_aggregation" {
  source = "../utils/aggregator"
  conf_list = [{
    env = merge({
      Authenticator__RequireAuthentication = local.authentication_require_authentication
      Authenticator__RequireAuthorization  = local.authentication_require_authorization
    }, var.extra_conf.core)
  }]
  materialize_configmap = {
    name      = "core-configmap"
    namespace = var.namespace
  }
}
