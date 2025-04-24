# Helper resource to download Atlas CA certificate if needed
resource "null_resource" "download_atlas_certificate" {
  count = var.download_atlas_certificate ? 1 : 0

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/certs && curl -o ${path.module}/certs/ca.pem https://www.mongodb.org/static/tls/ca.pem"
  }
}

# Create kubernetes secret for MongoDB Atlas CA certificate
resource "kubernetes_secret" "mongodb_atlas_certificates" {
  count = fileexists("${path.module}/certs/ca.pem") ? 1 : 0

  metadata {
    name      = "mongodb-atlas-certificates"
    namespace = var.namespace
  }

  data = {
    "mongodb-ca-cert" = file("${path.module}/certs/ca.pem")
  }

  type = "Opaque"
}

# Create a local copy of the certificate for client use if it exists
resource "local_sensitive_file" "mongodb_client_certificate" {
  count = fileexists("${path.module}/certs/ca.pem") ? 1 : 0

  content         = file("${path.module}/certs/ca.pem")
  filename        = "${path.root}/generated/certificates/atlas/chain.pem"
  file_permission = "0600"

  # Create directory if it doesn't exist
  provisioner "local-exec" {
    command = "mkdir -p ${path.root}/generated/certificates/atlas"
  }

  depends_on = [null_resource.download_atlas_certificate]
}
