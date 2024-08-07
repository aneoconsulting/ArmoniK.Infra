module "core_aggregation" {
  source = "../utils/aggregator"
  conf_list = [{
    env = {
      Authenticator__RequireAuthentication = local.authentication_require_authentication
      Authenticator__RequireAuthorization  = local.authentication_require_authorization
    }
    },
    {
      env = var.extra_conf.core
  }]
  materialize_configmap = {
    name      = "core-configmap"
    namespace = var.namespace
  }
}
