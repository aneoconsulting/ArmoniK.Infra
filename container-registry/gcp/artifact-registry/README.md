# Google Artifact Registry

The Google Artifact Registry provides a single location for storing and managing your packages and Docker container images.

This module creates a Google Artifact Registry of docker images with these possibilities :

* Enable or disable mutability.
* Add some rights for a list of users

<!-- Enable or disable the force delete -->
<!-- Choose the encryption type -->
<!-- Set a lifecycle policy -->

This module must be used with these constraints:

* Use the same availability zone to all the repositories.
* Give the image name and the tag of all the images

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:
:glob:

examples/**
```

