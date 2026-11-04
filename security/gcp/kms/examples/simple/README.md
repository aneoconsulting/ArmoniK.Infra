## Simple KMS

A key ring with one default key. Uses the [kms module](../..).

```bash
terraform init
terraform apply -var project=<project>
terraform destroy -var project=<project>
```

A key ring cannot be deleted, and a deleted crypto key keeps its name retired for good: `terraform destroy` merely
drops them from the state and schedules the key versions for destruction. Before applying again, import what is left:

```bash
terraform import -var project=<project> 'module.simple_kms.google_kms_key_ring.key_ring' projects/<project>/locations/global/keyRings/simple-kms
terraform import -var project=<project> 'module.simple_kms.google_kms_crypto_key.keys["simple-key"]' projects/<project>/locations/global/keyRings/simple-kms/cryptoKeys/simple-key
```

An imported key whose versions are scheduled for destruction has no usable version until restored
(`gcloud kms keys versions restore` then `enable`).
