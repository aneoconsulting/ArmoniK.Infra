locals {
  script_install_docker     = "install_docker.sh"
  script_install_kubernetes = "install_kubernetes.sh"

  default_cni_cidrs = {
    "flannel" = "10.244.0.0/16"
    "calico"  = "192.168.0.0/16"
  }
  cni_cidr = coalesce(var.cni_pluggin_cidr, local.default_cni_cidrs[var.cni_pluggin])
}

resource "null_resource" "install_kubernetes_cluster_node_masters" {
  connection {
    type        = "ssh"
    user        = var.user
    private_key = var.tls_private_key_pem
    host        = var.master_public_ip
    port        = 22
  }
  provisioner "file" {
    content = templatefile("${path.module}/scripts/${local.script_install_docker}",
      {
        master_public_ip  = var.master_public_ip
        master_private_ip = var.master_private_ip
        token             = var.kubeadm_token
        node              = "master"
        node_name         = var.master_node_name
        user              = var.user
        cni_pluggin       = var.cni_pluggin
    })
    destination = "/tmp/${local.script_install_docker}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo /bin/bash /tmp/${local.script_install_docker}"
    ]
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/${local.script_install_kubernetes}",
      {
        master_public_ip    = var.master_public_ip
        master_private_ip   = var.master_private_ip
        token               = var.kubeadm_token
        node                = "master"
        node_name           = var.master_node_name
        user                = var.user
        cni_pluggin         = var.cni_pluggin
        cni_cidr            = local.cni_cidr
        loadbalancer_plugin = var.loadbalancer_plugin
    })
    destination = "/tmp/${local.script_install_kubernetes}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo /bin/bash /tmp/${local.script_install_kubernetes}"
    ]
  }
}
