# The add-ons of addons.tf take over these objects under the same names, so Terraform must never delete them.
# To be removed in ArmoniK 2.25
#
# Upgrading a cluster that ran the EBS/EFS CSI drivers and the ENIConfigs as Helm releases (EKS module v20), where
# <eks> is the address of this module, such as module.eks; helm takes HELM_DRIVER=configmap when its provider sets
# helm_driver = "configmap", as the examples do:
#   1. Keep cluster_create_kms_key = true: such a cluster encrypts its secrets with the key the EKS module created,
#      whatever cluster_encryption_config says, and EKS cannot change it.
#   2. The node IMDS hop limit drops to 1, so once the nodes roll, pods no longer get the node role: first give every
#      workload relying on it its own role, fluent-bit included (service-account/aws with create_service_account =
#      false, and the service_account_annotations of the fluent-bit module).
#   3. Forget the objects below. The removed blocks cannot do it here: forgetting needs the helm and kubernetes
#      providers, configured from the cluster being updated, which makes a dependency cycle. They only guarantee that
#      an object left in the state is never destroyed.
#        terraform state rm <eks>.helm_release.ebs_csi <eks>.helm_release.efs_csi <eks>.helm_release.eni_config \
#          <eks>.kubernetes_service_account.ebs_csi_driver_controller <eks>.kubernetes_service_account.ebs_csi_driver_node \
#          <eks>.kubernetes_service_account.efs_csi_driver_controller <eks>.kubernetes_service_account.efs_csi_driver_node \
#          <eks>.kubernetes_config_map_v1_data.amazon_vpc_cni
#   4. Uninstall the CSI driver releases: their Deployment and DaemonSet selectors are immutable, so the add-ons cannot
#      adopt them. Mounted volumes stay mounted, but no volume is provisioned, attached or mounted until step 5 ends.
#        helm -n kube-system uninstall ebs-csi efs-csi
#   5. Apply with Terraform >= 1.7, as an identity allowed iam:UpdateAssumeRolePolicy (the CSI roles gain the Pod
#      Identity trust). The vpc-cni, kube-proxy and coredns add-ons adopt the running objects
#      (resolve_conflicts_on_create = OVERWRITE); the CSI add-ons recreate the drivers; the nodes roll.
#      Then apply a second time: the EKS module attaches AmazonEKSVPCResourceController to the cluster role under
#      another address, and the first apply deletes the old attachment in parallel with creating the new one. If the
#      deletion lands last, the policy is detached and Windows pods get no IP until the second apply re-attaches it.
#   6. Release the ENIConfigs: with vpc_cni_custom_networking = true, the vpc-cni add-on owns them, so only delete the
#      release record (in the former chart_namespace, default by default; a secret with Helm's default driver):
#        kubectl -n default delete configmap -l owner=helm,name=add-subnet
#      otherwise uninstall the release: helm -n default uninstall add-subnet
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
