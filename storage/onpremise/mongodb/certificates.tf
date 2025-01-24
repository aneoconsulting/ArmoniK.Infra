resource "local_sensitive_file" "mongodb_client_certificate" {
  content         = data.kubernetes_secret.mongodb_certificates.data["mongodb-ca-cert"]
  filename        = "${path.root}/generated/certificates/mongodb/chain.pem"
  file_permission = "0600"
}