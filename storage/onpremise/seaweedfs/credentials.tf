resource "random_string" "access_key" {
  length  = 20
  special = false
}

resource "random_password" "secret_key" {
  length  = 40
  special = false
}
