locals {
  # NFS node selector
  node_selector_keys   = keys(var.nfs_client.node_selector)
  node_selector_values = values(var.nfs_client.node_selector)
}


