# Google Artifact Registry

The Google Artifact Registry provides a single location for storing and managing your packages and Docker container images.

This module creates a Google Artifact Registry of docker images with these possibilities :

* Enable or disable mutability.
* Add some rights for a list of users
* Serve public images through pull-through caches (`pull_through_cache`).

<!-- Enable or disable the force delete -->
<!-- Choose the encryption type -->
<!-- Set a lifecycle policy -->

This module must be used with these constraints:

* Use the same availability zone to all the repositories.
* Give the image name and the tag of all the images

## Pull-through caches

Setting `pull_through_cache` (`{}` for the defaults) creates:

* One remote repository per public registry (Docker Hub, public.ecr.aws, quay.io, ghcr.io and registry.k8s.io by
  default): a pull-through cache that fetches an image from upstream on its first pull, then serves it from the cache.
* A virtual repository (output `url`) in front of the registry created by this module (output `standard_url`) and of
  the caches, trying each one in priority order. The registry comes first by default.

Nothing goes through the machine running Terraform, so `docker_images` is no longer needed and is deprecated.

An image is pulled from the virtual repository under its upstream path, for instance
`<url>/dockerhubaneo/armonik_control_plane:<tag>`. Official Docker Hub images keep their `library/` prefix
(`<url>/library/redis:<tag>`). Two registries can serve the same path, so an image of another registry than Docker Hub is
better pulled from its own cache (output `remote_urls`), for instance `<remote_urls["ghcr"]>/kedacore/keda:<tag>`.

To deploy a locally built image, push it to the registry under the same path:

```bash
gcloud auth configure-docker <region>-docker.pkg.dev
docker push <standard_url>/dockerhubaneo/armonik_control_plane:<tag>
```

The virtual repository then serves it in place of the upstream image of the same path and tag.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```

