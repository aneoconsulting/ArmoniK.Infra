/* Ideally present, but there is a bug with Terraform (v 1.7.4) that currently prevents from deploying this resource 
resource "generic_local_sensitive_file" "mongodb_client_certificate" {
  content = base64decode(data.kubernetes_secret.mongodb_certificates.binary_data["mongodb-ca-cert"])
  path    = "${path.root}/generated/certificates/mongodb/chain.pem"
  mode    = "0600"
}
*/
