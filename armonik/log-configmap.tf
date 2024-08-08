locals {
  logging_level_routing = var.logging_level == "Information" ? "Warning" : var.logging_level
}
# configmap with all the environment variables to set loglevels
module "log_aggregation" {
  source = "../utils/aggregator"
  conf_list = flatten([{
    env = {
      "Serilog__MinimumLevel" : var.logging_level,
      "Serilog__MinimumLevel__Override__Microsoft.AspNetCore.Hosting.Diagnostics" : local.logging_level_routing,
      "Serilog__MinimumLevel__Override__Microsoft.AspNetCore.Routing.EndpointMiddleware" : local.logging_level_routing,
      "Serilog__MinimumLevel__Override__Serilog.AspNetCore.RequestLoggingMiddleware" : local.logging_level_routing,
      "Serilog__MinimumLevel__Override__Microsoft.AspNetCore.Routing" : local.logging_level_routing,
      "Serilog__MinimumLevel__Override__Microsoft.AspNetCore.Server.Kestrel" : local.logging_level_routing,
      "Serilog__MinimumLevel__Override__Grpc.AspNetCore.Server.ServerCallHandler" : local.logging_level_routing,
      "Serilog__MinimumLevel__Override__Microsoft.Extensions.Diagnostics.HealthChecks" : local.logging_level_routing,
      "Serilog__MinimumLevel__Override__Microsoft.AspNetCore.Authorization" : local.logging_level_routing,
      "Serilog__MinimumLevel__Override__Microsoft.Extensions.Http.DefaultHttpClientFactory" : local.logging_level_routing,
      "Serilog__MinimumLevel__Override__ArmoniK.Core.Common.Auth.Authentication.Authenticator" : local.logging_level_routing
    }
  }, var.configurations.log])
  materialize_configmap = {
    name      = "log-configmap"
    namespace = var.namespace
  }
}
