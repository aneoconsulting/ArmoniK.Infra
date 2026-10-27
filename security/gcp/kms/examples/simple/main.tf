module "simple_kms" {
  source        = "../../../kms"
  key_ring_name = "simple-kms"
  location      = "global"
  crypto_keys   = { "simple-key" = {} }
}
