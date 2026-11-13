# GCP Cloud Storage

Bucket for ArmoniK object storage (native GCS adapter) or for shared files such as the worker DLLs.

This module creates:

* A bucket, with optional uniform bucket-level access, public access prevention and hierarchical namespace.
* Optional lifecycle rules, versioning or retention policy, Autoclass, soft delete retention, access logs, website,
  CORS and dual-region placement.
* Optional encryption with a Cloud KMS key, IAM roles and ACLs on the bucket.
* A Kubernetes secret with the HMAC credentials of the S3 adapter of Core, empty unless `username` and `password`
  are set.

> Note: set `soft_delete_retention_days = 0` on the object storage bucket, whose deleted objects are not worth
> paying 7 more days for.

> Note: a flat bucket starts at ~1000 object writes per second and doubles about every 20 minutes; beyond, GCS answers
> 429 and Core stops after too many errors. Core writes 2 objects per task (payload and result): ramp the load up, or
> set `hierarchical_namespace = true` (~8000 writes per second from the start, operations ~30 % dearer).

## Core adapter

The `env` and `env_secret` outputs configure the object storage of Core. They carry the settings of both adapters
that Core can use on GCS; `adapter_class_name` and `adapter_absolute_path` select the one Core loads.

### Native GCS adapter (default)

Core authenticates with Application Default Credentials, Workload Identity on GKE, so the module needs no
credentials. Grant the Core identity the object permissions, plus `storage.buckets.get`, which Core calls at startup
to check the bucket:

```hcl
module "object_storage" {
  source   = "./storage/gcp/gcs"
  name     = "armonik-object-storage"
  location = "europe-west1"
  roles = {
    "<role holding the object permissions and storage.buckets.get>" = [module.core_service_account.member]
  }
}
```

### S3 adapter

Core reaches the bucket through the XML API of GCS with an HMAC key. Select the adapter and give the key: the module
stores it in the Kubernetes secret listed in `env_secret`.

```hcl
resource "google_storage_hmac_key" "core" {
  service_account_email = "<service account allowed on the bucket>"
}

module "object_storage" {
  source                = "./storage/gcp/gcs"
  name                  = "armonik-object-storage"
  location              = "europe-west1"
  namespace             = "armonik"
  adapter_class_name    = "ArmoniK.Core.Adapters.S3.ObjectBuilder"
  adapter_absolute_path = "/adapters/object/s3/ArmoniK.Core.Adapters.S3.dll"
  username              = google_storage_hmac_key.core.access_id
  password              = google_storage_hmac_key.core.secret
  # The S3 adapter checks the bucket with GetBucketAcl, which GCS rejects with uniform bucket-level access
  uniform_bucket_level_access = false
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
