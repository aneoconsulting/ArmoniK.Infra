module "simple_memorystore" {
    source     = "../../../memorystore"
    region     = "europe-west9"
    project    = "armonik-gcp-13469"
    name       = "redis-test"
}