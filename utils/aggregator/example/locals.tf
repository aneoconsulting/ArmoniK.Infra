locals {
  extra_conf = {
    core = {
      Amqp__AllowHostMismatch                    = true
      Amqp__MaxPriority                          = "10"
      Amqp__MaxRetries                           = "5"
      Amqp__QueueStorage__LockRefreshPeriodicity = "00:00:45"
    }
    control = {
      Submitter__MaxErrorAllowed = 50
    }
    worker = {
      target_zip_path = "/tmp"
    }
  }
}


module "core_aggregation" {
  source = "../../aggregator"
  conf_list = [{
    env = merge({
      USER     = "user"
      PASSWORD = "password"
    }, local.extra_conf.core)
  }]
  materialize_configmap = {
    name      = "extra"
    namespace = "default"
  }
}
