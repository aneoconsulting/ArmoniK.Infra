# Key rings are never deleted: a random suffix lets the example be applied again after a destroy
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

module "simple_kms" {
  source        = "../../../kms"
  key_ring_name = "simple-kms-${random_string.suffix.result}"
  location      = "global"
  crypto_keys   = { "simple-key" = {} }
}
