resource "random_string" "mongodb_application_user" {
  length  = 8
  special = false
  numeric = false
}

resource "random_password" "mongodb_application_password" {
  length  = 16
  special = false
}
