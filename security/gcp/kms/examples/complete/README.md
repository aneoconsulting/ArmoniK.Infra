## Complete KMS

Symmetric and signing keys, rotation, and IAM roles for the current user on the key ring and on a key. Uses the
[kms module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```

A key ring cannot be deleted, and a deleted crypto key keeps its name retired for good: `terraform destroy` merely
drops them from the state and schedules the key versions for destruction. Before applying again, import what is left:

```bash
terraform import -var project=<project> 'module.complete_kms.google_kms_key_ring.key_ring' projects/<project>/locations/europe/keyRings/complete-kms
terraform import -var project=<project> 'module.complete_kms.google_kms_crypto_key.keys["key-1"]' projects/<project>/locations/europe/keyRings/complete-kms/cryptoKeys/key-1
terraform import -var project=<project> 'module.complete_kms.google_kms_crypto_key.keys["key-4"]' projects/<project>/locations/europe/keyRings/complete-kms/cryptoKeys/key-4
terraform import -var project=<project> 'module.complete_kms.google_kms_crypto_key.keys["key-3"]' projects/<project>/locations/europe/keyRings/complete-kms/cryptoKeys/key-3
```

An imported key whose versions are scheduled for destruction has no usable version until restored
(`gcloud kms keys versions restore` then `enable`).
