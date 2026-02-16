# GCP Memorystore for Redis

Google Memorystore for Redis provides a fully-managed service that is powered by the Redis in-memory data store to build
application caches that provide sub-millisecond data access. The official
documentations: [Google Memorystore for Redis](https://cloud.google.com/memorystore/docs/redis/)
and [Memorystore configuration for Redis](https://cloud.google.com/memorystore/docs/redis/reference/rest/v1/projects.locations.instances).

This module creates a Memorystore for Redis with these possibilities :

* Configure the persistence for the Memorystore.
* Configure the maintenance policy for the Memorystore.
* The Transit encryption is set to true by default.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:
:glob:

examples/**
```

