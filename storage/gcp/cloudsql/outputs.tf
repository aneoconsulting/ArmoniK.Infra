output "name" {
  description = "Name of the Cloud SQL instance."
  value       = google_sql_database_instance.postgresql.name
}

output "connection_name" {
  description = "Connection name of the instance, <project>:<region>:<name>."
  value       = google_sql_database_instance.postgresql.connection_name
}

# The name of the DNS automation, recorded by Cloud SQL in the network with the endpoint and carried by the server
# certificate. The other name of the instance, dns_name (<uid>.<region>.sql.goog), has no record unless one is created.
output "host" {
  description = "DNS name of the instance in the client network, the one its server certificate carries."
  value = one([
    for dns in google_sql_database_instance.postgresql.dns_names : trimsuffix(dns.name, ".")
    if endswith(trimsuffix(dns.name, "."), ".sql-psc.goog")
  ])
}

output "ip_address" {
  description = "IP address of the Private Service Connect endpoint in the client network."
  value       = google_sql_database_instance.postgresql.settings[0].ip_configuration[0].psc_config[0].psc_auto_connections[0].ip_address
}

output "port" {
  description = "PostgreSQL port."
  value       = 5432
}

output "pooler_port" {
  description = "Port of the managed connection poolers on the host, null without connection_pooling. The poolers do not document logical replication connections, which the WAL broadcaster of Core opens on the same host and port as its pool."
  value       = var.connection_pooling.enabled ? 6432 : null
}

output "database" {
  description = "Name of the database."
  value       = google_sql_database.armonik.name
}

output "username" {
  description = "PostgreSQL user, owner of the database."
  value       = google_sql_user.armonik.name
  # Usable by Core once it holds the REPLICATION attribute
  depends_on = [google_sql_provision_script.replication]
}

output "password" {
  description = "Password of the PostgreSQL user."
  value       = random_password.user.result
  sensitive   = true
  depends_on  = [google_sql_provision_script.replication]
}

output "ca_cert" {
  description = "PEM certificates of the CA that issues the server certificate, to verify it against."
  value       = join("\n", [for cert in google_sql_database_instance.postgresql.server_ca_cert : cert.cert])
}

output "monitoring_username" {
  description = "Read-only PostgreSQL user of the monitoring tools, null without monitoring_user."
  value       = try(google_sql_user.monitoring[0].name, null)
  # Usable once it can read the tables
  depends_on = [google_sql_provision_script.monitoring]
}

output "monitoring_password" {
  description = "Password of the monitoring user, null without monitoring_user."
  value       = try(random_password.monitoring[0].result, null)
  sensitive   = true
  depends_on  = [google_sql_provision_script.monitoring]
}
