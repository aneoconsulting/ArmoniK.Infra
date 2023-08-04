module "simple_kms_example" {
  source              = "../../../kms"
  kms_crypto_key_name = "test-2"
  kms_key_ring_name   = "test"
}
