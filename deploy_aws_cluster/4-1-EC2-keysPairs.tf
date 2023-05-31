# Create (and display) an SSH key
resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "public_key" {
  key_name   = "public_key_${var.suffix}"
  public_key = tls_private_key.ssh-key.public_key_openssh
}

