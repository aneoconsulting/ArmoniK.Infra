## Autopilot GKE Cluster

A regional Autopilot cluster restricted to two zones, secrets encrypted with Cloud KMS, no public IP endpoint
and the DNS endpoint open to IAM-authenticated callers. Uses the [gke-cluster module](../..) with `autopilot = true`.

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```

A key ring cannot be deleted, and a deleted crypto key keeps its name retired for good: `terraform destroy` merely
drops them from the state and schedules the key versions for destruction. Before applying again, import what is left:

```bash
terraform import -var project=<project> 'module.kms.google_kms_key_ring.key_ring' projects/<project>/locations/europe-west9/keyRings/gke-autopilot
terraform import -var project=<project> 'module.kms.google_kms_crypto_key.keys["gke-secrets"]' projects/<project>/locations/europe-west9/keyRings/gke-autopilot/cryptoKeys/gke-secrets
```

An imported key whose versions are scheduled for destruction has no usable version until restored
(`gcloud kms keys versions restore` then `enable`).
