# The add-ons of addons.tf take over these objects under the same names, so Terraform must forget them without deleting them.
# To be removed in ArmoniK 2.25
#
# Upgrading a cluster that ran the EBS/EFS CSI drivers and the ENIConfigs as Helm releases:
#   1. Apply with Terraform >= 1.7. The plan creates the add-ons, which adopt the running objects
#      (resolve_conflicts_on_create = OVERWRITE), swaps the CSI role policies to the AWS managed ones, and
#      forgets the objects below; it must not destroy anything in Kubernetes.
#   2. Delete the leftover Helm release records, never with `helm uninstall`, which would delete the
#      objects the add-ons now own (add-subnet lives in the former chart_namespace, `default` by default):
#        kubectl -n kube-system delete secret -l owner=helm,name=ebs-csi
#        kubectl -n kube-system delete secret -l owner=helm,name=efs-csi
#        kubectl -n default delete secret -l owner=helm,name=add-subnet
# A cluster still on Helm releases must go through a version that has these blocks before upgrading further.
removed {
  from = helm_release.ebs_csi
  lifecycle {
    destroy = false
  }
}

removed {
  from = helm_release.efs_csi
  lifecycle {
    destroy = false
  }
}

removed {
  from = helm_release.eni_config
  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_service_account.ebs_csi_driver_controller
  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_service_account.ebs_csi_driver_node
  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_service_account.efs_csi_driver_controller
  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_service_account.efs_csi_driver_node
  lifecycle {
    destroy = false
  }
}

removed {
  from = kubernetes_config_map_v1_data.amazon_vpc_cni
  lifecycle {
    destroy = false
  }
}
