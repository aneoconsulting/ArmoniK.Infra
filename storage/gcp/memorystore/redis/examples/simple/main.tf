module "simple_memorystore_for_redis" {
  source         = "../../../redis"
  name           = "simple-redis-test"
  memory_size_gb = 1
}
