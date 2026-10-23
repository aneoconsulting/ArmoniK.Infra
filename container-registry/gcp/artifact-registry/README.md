# Google Artifact Registry

The Google Artifact Registry provides a single location for storing and managing your packages and Docker container images.

This module creates Docker repositories in Google Artifact Registry, all reachable through a single URL:

* One remote repository per public registry (Docker Hub, public.ecr.aws, quay.io, ghcr.io and registry.k8s.io by
  default): a pull-through cache that fetches an image from upstream on its first pull, then serves it from the cache.
* An optional standard repository for images pushed by their owner, such as private workers.
* A virtual repository in front of them, which tries each one in priority order. Its URL (output `url`) replaces the
  registry of every image, `global.imageRegistry` in the ArmoniK charts.
* Optional encryption of the remote and standard repositories with a Cloud KMS key, and IAM roles on the virtual and
  standard repositories.

Two images of different upstream registries sharing the same path resolve to the one with the highest priority.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```

