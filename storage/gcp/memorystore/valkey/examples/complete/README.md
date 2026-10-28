## Complete Valkey

An instance with a replica over several zones, RDB snapshots, a maintenance window and encryption with Cloud KMS,
in a VPC with a dedicated subnet for the Private Service Connect endpoints. Uses the [valkey module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```

A key ring cannot be deleted, and a deleted crypto key keeps its name retired for good: `terraform destroy` merely
drops them from the state and schedules the key versions for destruction. Before applying again, import what is left:

```bash
terraform import -var project=<project> 'module.kms.google_kms_key_ring.key_ring' projects/<project>/locations/europe-west9/keyRings/valkey-complete
terraform import -var project=<project> 'module.kms.google_kms_crypto_key.keys["valkey"]' projects/<project>/locations/europe-west9/keyRings/valkey-complete/cryptoKeys/valkey
```

An imported key whose versions are scheduled for destruction has no usable version until restored
(`gcloud kms keys versions restore` then `enable`).
