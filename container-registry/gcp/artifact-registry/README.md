# GCP Artifact Registry

Container images of a deployment, behind a single URL.

This module creates:

* One remote repository (pull-through cache) per public registry: Docker Hub, public.ecr.aws, quay.io, ghcr.io and
  registry.k8s.io by default.
* An optional standard repository for pushed images, such as private workers.
* A virtual repository in front of them, tried by priority. Its URL (output `url`) is the image registry,
  `global.imageRegistry` in the ArmoniK charts.

> Note: an image path found in two upstream registries resolves to the one with the highest priority.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
