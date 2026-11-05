# S3 identities read by SeaweedFS (allInOne.s3.existingConfigSecret), instead of the chart generated ones
resource "kubernetes_secret_v1" "s3_config" {
  metadata {
    name      = "${var.name}-s3-config"
    namespace = var.namespace
  }
  data = {
    seaweedfs_s3_config = jsonencode({
      identities = [{
        name = "armonik"
        credentials = [{
          accessKey = random_string.access_key.result
          secretKey = random_password.secret_key.result
        }]
        actions = ["Admin", "Read", "Write", "List", "Tagging"]
      }]
    })
  }
}

# Connection information
resource "kubernetes_secret_v1" "s3" {
  metadata {
    name      = "${var.name}-s3"
    namespace = var.namespace
  }
  data = {
    username              = random_string.access_key.result
    password              = random_password.secret_key.result
    url                   = local.url
    host                  = local.host
    port                  = local.port
    bucket_name           = var.seaweedfs.bucket_name
    must_force_path_style = local.must_force_path_style
    use_chunk_encoding    = local.use_chunk_encoding
    use_check_sum         = local.use_checksum
  }
}

resource "kubernetes_secret_v1" "s3_user" {
  metadata {
    name      = "${var.name}-s3-user"
    namespace = var.namespace
  }
  data = {
    username = random_string.access_key.result
    password = random_password.secret_key.result
  }
  type = "kubernetes.io/basic-auth"
}

# Credentials injected in the Core as environment variables
resource "kubernetes_secret_v1" "s3_user_credentials" {
  metadata {
    name      = "${var.name}-s3-user-credentials"
    namespace = var.namespace
  }
  data = {
    "S3__Login"    = random_string.access_key.result
    "S3__Password" = random_password.secret_key.result
  }
}
