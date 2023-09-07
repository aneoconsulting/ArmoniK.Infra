module "simple_kms" {
  source           = "../../../get-kms"
  key_ring_name    = "test"
  crypto_key_names = ["my-key-name","my-key-name2"]
}
