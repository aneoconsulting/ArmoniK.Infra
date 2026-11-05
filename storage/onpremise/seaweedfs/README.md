# SeaweedFS

SeaweedFS object storage compatible with the Amazon S3 API, deployed with the official Helm chart in all-in-one mode (one pod). It replaces the [MinIO module](../minio), whose community images are no longer published.

The chart always renders a `<name>-sftp-secret` in all-in-one mode, as a pre-install hook with `helm.sh/resource-policy: keep`, whatever its SFTP settings: it is left behind on destroy (harmless, no SFTP server runs) and reused by the next install.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
