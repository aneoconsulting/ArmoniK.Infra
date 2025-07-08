
locals {
  token = "${random_string.token_id.result}.${random_string.token_secret.result}"
}

# call the module for kubeadm cluster creation
module "install_kubeadm_cluster" {
  source = "../../../kubeadm"

  master_public_ip            = var.master.public_dns
  master_private_ip           = var.master.private_dns
  tls_private_key_pem_content = file(var.master.tls_private_key_pem_file)
  user                        = var.user
  kubeadm_token               = local.token
  cni_pluggin                 = "flannel" # calico or flannel
  loadbalancer_plugin         = "metalLB"
  workers                     = var.workers
}

# left part of the kubeadm token.
resource "random_string" "token_id" {
  length  = 6
  special = false
  upper   = false
}

# right part of the kubeadm token.
resource "random_string" "token_secret" {
  length  = 16
  special = false
  upper   = false
}

#------------------------------------------------------------------------------#
# Download kubeconfig file from master node to local machine
#------------------------------------------------------------------------------#
resource "null_resource" "download_kubeconfig_file" {
  provisioner "local-exec" {
    command = <<EOF
    cp ${var.master.tls_private_key_pem_file} $HOME/cluster_private_key.pem
    chmod 400 $HOME/cluster_private_key.pem
    scp -i $HOME/cluster_private_key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.user}@${var.master.public_dns}:/tmp/admin.conf $HOME/.kube/config_remote
    rm $HOME/cluster_private_key.pem
    EOF
  }
  depends_on = [
    module.install_kubeadm_cluster
  ]
}
