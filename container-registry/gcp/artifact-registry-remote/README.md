# GCP Artifact Registry pull-through caches

Pull-through caches of public container registries, so that the nodes pull from Artifact Registry in their region
instead of the internet: one Docker remote repository per upstream (Docker Hub, GHCR, Quay, registry.k8s.io and
public ECR by default). A pull of an image not cached yet fetches it from the upstream and keeps it.

This module creates:

* One remote repository per entry of `repositories`, named `<name>-<key>`, with optional upstream credentials read
  from Secret Manager (the module grants the Artifact Registry service agent access to the secrets).
* Reader roles for the given members on every repository, such as the node service account of a GKE cluster.
* An optional cleanup policy deleting the cached images older than a duration.

The image prefix of each upstream is in the `urls` output. An image keeps its upstream path behind it:
`quay.io/jetstack/cert-manager-controller` becomes `<urls.quay>/jetstack/cert-manager-controller`, and the official
Docker Hub images take the `library/` prefix (`<urls.dockerhub>/library/busybox`).

> Note: there is deliberately no virtual repository over the caches. A virtual repository serves an image from the
> first upstream, by priority, that has its path. A namespace free on a higher-priority upstream can then be claimed
> by anyone to shadow an image of a lower-priority one (dependency confusion). With one repository per upstream,
> each image has a single source.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
