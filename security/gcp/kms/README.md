# Cloud KMS

Cloud Key Management Service allows you to create, import, and manage cryptographic keys and perform cryptographic
operations in a single centralized cloud service. You can use these keys and perform these operations by using Cloud KMS
directly, by using Cloud HSM or Cloud External Key Manager, or by using Customer-Managed Encryption Keys (CMEK) integrations
within other Google Cloud services.

This module create a key ring with a list of crypto keys with these possibilities :

* Create a KeyRing.
* Configure the IAM policy for the newly created key ring.
* Create a map of crypto keys.
* Configure the IAM policy for the newly created crypto keys.

> Note: KeyRings cannot be deleted from Google Cloud Platform. Destroying a Terraform-managed KeyRing will remove it from state but will not delete the resource from the project. See [Documentation](https://cloud.google.com/kms/docs/destroy-restore#:~:text=Note%3A%20Key%20rings%2C%20keys%2C,unless%20it%20has%20been%20destroyed.).

> Note: CryptoKeys cannot be deleted from Google Cloud Platform. Destroying a Terraform-managed CryptoKey will remove it from state and delete all CryptoKeyVersions, rendering the key unusable, but will not delete the resource from the project. When Terraform destroys these keys, any data previously encrypted with these keys will be irrecoverable. For this reason, it is strongly recommended that you add lifecycle hooks to the resource to prevent accidental destruction.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```

