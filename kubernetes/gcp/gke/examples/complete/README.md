## Complete GKE Cluster

A zonal cluster with a system pool and a tainted spot pool scaling from zero on local SSDs, node auto-provisioning,
secrets and boot disks encrypted with Cloud KMS, and a control plane reachable through its DNS endpoint only, written
to `generated/kubeconfig`. Uses the [gke module](../..).

```bash
terraform init
terraform apply -var project=<project>
KUBECONFIG=generated/kubeconfig kubectl get nodes
terraform destroy -var project=<project>
```

A key ring cannot be deleted, and a deleted crypto key keeps its name retired for good: `terraform destroy` merely
drops them from the state and schedules the key versions for destruction. Before applying again, import what is left:

```bash
terraform import -var project=<project> 'module.kms.google_kms_key_ring.key_ring' projects/<project>/locations/europe-west9/keyRings/gke-complete
terraform import -var project=<project> 'module.kms.google_kms_crypto_key.keys["gke-secrets"]' projects/<project>/locations/europe-west9/keyRings/gke-complete/cryptoKeys/gke-secrets
terraform import -var project=<project> 'module.kms.google_kms_crypto_key.keys["gke-disks"]' projects/<project>/locations/europe-west9/keyRings/gke-complete/cryptoKeys/gke-disks
```

An imported key whose versions are scheduled for destruction has no usable version until restored
(`gcloud kms keys versions restore` then `enable`).
