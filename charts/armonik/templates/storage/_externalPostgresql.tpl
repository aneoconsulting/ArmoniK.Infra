{{/*
Configuration for an external PostgreSQL server (RDS, Cloud SQL, on-prem) forwarded to ArmoniK Core,
through armonik.postgresqlConnection.conf.
*/}}
{{- define "armonik.externalPostgresql.conf" -}}
{{- $pg := list .Values "dependencies" "externalPostgresql" | include "armonik.utils.index" | fromYaml -}}
{{- if $pg.enabled }}
  {{- $_ := required "dependencies.externalPostgresql.host is required when dependencies.externalPostgresql.enabled" $pg.host -}}
  {{- $_ = required "dependencies.externalPostgresql.database is required when dependencies.externalPostgresql.enabled" $pg.database -}}
  {{- $_ = required "dependencies.externalPostgresql.credentials.secret is required when dependencies.externalPostgresql.enabled" ($pg.credentials | default dict).secret -}}
  {{- if not (kindIs "bool" $pg.ssl) -}}
    {{- $_ = set $pg "ssl" true -}}
  {{- end -}}
  {{- if $pg.ssl -}}
    {{- $_ = required "dependencies.externalPostgresql.ca.secret is required when dependencies.externalPostgresql.ssl is true" ($pg.ca | default dict).secret -}}
  {{- end }}
{{ list $pg . | include "armonik.postgresqlConnection.conf" }}
{{- end }}
{{- end -}}
