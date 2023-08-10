module "simple_memorystore_for_mecached_instance" {
  source         = "../../../memcache"
  name           = "simple-memcache-test"
  cpu_count      = 1
  memory_size_mb = 64
  node_count     = 1
}
