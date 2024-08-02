# configmap with all the variables
module "job_aggregation" {
  source = "../utils/aggregator"
  conf_list = [{
    env = var.jobs_in_database_extra_conf
  }]
  materialize_configmap = {
    name      = "jobs-in-database-configmap"
    namespace = var.namespace
  }
}
