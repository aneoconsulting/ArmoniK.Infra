# GCP Cloud SQL for PostgreSQL

Cloud SQL for PostgreSQL instance for the table storage of ArmoniK Core, reached from a VPC through Private Service
Connect only: no public IP, no VPC peering.

This module creates:

* The instance, PostgreSQL 18 by default, with the flags Core needs: `cloudsql.logical_decoding` (Core streams the
  changes of its tables through logical replication) and a `max_connections` sized for many Core processes.
* A Private Service Connect endpoint in `network` with a DNS record of the instance (`host` output). Cloud SQL
  creates both, and the service connection policy behind them. The server certificate, issued by a Google-managed CA
  (`ca_cert` output), carries that DNS name, so clients verify the CA and the host.
* The database and its owner, with a generated password, granted the `REPLICATION` attribute by a provision script
  run as `postgres` through the Cloud SQL API, whose password is kept in a regional Secret Manager secret.

> Note: a deleted instance keeps its name reserved for up to a week. A deployment destroyed and created again needs
> a new name, such as one with a random suffix.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

```{toctree}
:maxdepth: 2
:glob:

examples/**
```
