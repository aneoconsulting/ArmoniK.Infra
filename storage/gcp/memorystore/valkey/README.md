# GCP Memorystore for Valkey

Valkey instance for the ArmoniK object storage, through the Redis adapter of Core, as a low-latency alternative to
the [GCS module](../../gcs).

This module creates:

* A Valkey instance without cluster mode (one shard, optional replicas), reached through Private Service Connect
  endpoints created automatically in the given network, with TLS and without authentication by default.
* Optional persistence, maintenance window, zone distribution and encryption with a Cloud KMS key.

> Note: the network needs a service connection policy of class `gcp-memorystore` in the instance region, from the
> `service_connection_policies` input of the GCP vpc module.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
