## Autopilot GKE

A regional Autopilot cluster restricted to two zones, secrets encrypted with Cloud KMS, an authorized network
on the public endpoint and the DNS endpoint open to IAM-authenticated callers. Uses the [gke module](../..) with `autopilot = true`.

```bash
terraform init
terraform apply -var project=<project> -var authorized_cidr_block=$(curl -s ifconfig.me)/32
terraform destroy -var project=<project> -var authorized_cidr_block=$(curl -s ifconfig.me)/32
```

A key ring cannot be deleted, and a deleted crypto key keeps its name retired for good: `terraform destroy` merely
drops them from the state and schedules the key versions for destruction. Before applying again, import what is left:

```bash
terraform import -var project=<project> -var authorized_cidr_block=$(curl -s ifconfig.me)/32 'module.kms.google_kms_key_ring.key_ring' projects/<project>/locations/europe-west9/keyRings/gke-autopilot
terraform import -var project=<project> -var authorized_cidr_block=$(curl -s ifconfig.me)/32 'module.kms.google_kms_crypto_key.keys["gke-secrets"]' projects/<project>/locations/europe-west9/keyRings/gke-autopilot/cryptoKeys/gke-secrets
```

An imported key whose versions are scheduled for destruction has no usable version until restored
(`gcloud kms keys versions restore` then `enable`).
