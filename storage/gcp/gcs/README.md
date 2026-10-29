# GCP Cloud Storage

Bucket for ArmoniK object storage (native GCS adapter) or for shared files such as the worker DLLs.

This module creates:

* A bucket with uniform bucket-level access and public access prevention enforced by default.
* Optional lifecycle rules, versioning or retention policy, Autoclass, soft delete retention, access logs and
  dual-region placement.
* Optional encryption with a Cloud KMS key, and IAM roles on the bucket.

> Note: the S3 adapter of Core, used on GCS through the XML API and an HMAC key, checks that the bucket exists
> with GetBucketAcl, which GCS rejects on a bucket with uniform bucket-level access: set
> `uniform_bucket_level_access = false` on the buckets it uses.

> Note: set `soft_delete_retention_days = 0` on the object storage bucket, whose deleted objects are not worth
> paying 7 more days for.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
