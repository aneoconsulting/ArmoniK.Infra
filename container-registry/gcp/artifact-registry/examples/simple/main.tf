module "simple_artifact_registry" {
  source      = "../../../artifact-registry"
  name        = "simple-test"
  description = "A simple artifact registry caching the default public registries"
}
