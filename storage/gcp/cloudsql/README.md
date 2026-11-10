# GCP Cloud SQL for PostgreSQL

Cloud SQL for PostgreSQL instance for the table storage of ArmoniK Core, reached from a VPC through Private Service
Connect only: no public IP, no VPC peering.

This module creates:

* The instance, PostgreSQL 18 by default, with the flags Core needs: `cloudsql.logical_decoding` (Core streams the
  changes of its tables through logical replication) and a `max_connections` sized for many Core processes.
* The service connection policy of `network` for Cloud SQL, on `psc_subnets`, unless the network already has one
  (one per network, region and service class): Cloud SQL then creates a Private Service Connect endpoint of the
  instance in `network`, with a DNS record of the instance (`host` output). The server certificate is issued by a
  Google-managed CA hierarchy shared by the instances of the region (`ca_cert` output).
* The database and its owner, with a generated password, granted the `REPLICATION` attribute by a provision script
  run as `postgres` through the Cloud SQL API, whose password is kept in a regional Secret Manager secret.

* Optionally (`monitoring_user`), a read-only user for the monitoring tools: `pg_monitor` (inherited from
  `cloudsqlsuperuser`), `SELECT` on the tables granted by their owner, and the `pg_stat_statements` extension.
* Query Insights (`query_insights`), the per-query statistics of the Cloud SQL console.
* In the `ENTERPRISE_PLUS` edition, optionally, the data cache (`data_cache`) and Managed Connection Pooling
  (`connection_pooling`): poolers on port 6432 of the same host (`pooler_port` output), the server still answering on
  5432 (`port` output).

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
