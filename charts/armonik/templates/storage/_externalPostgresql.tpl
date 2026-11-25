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
  {{- $pooler := $pg.pooler | default dict -}}
  {{- $connection := $pg -}}
  {{- if $pooler.host -}}
    {{- $connection = merge (dict "host" $pooler.host "port" ($pooler.port | default $pg.port)) $pg -}}
  {{- end }}
{{ list $connection . | include "armonik.postgresqlConnection.conf" }}
{{- end }}
{{- end -}}

{{/* events layer: the server itself, never pooler.host (see armonik.postgresql.eventsConf). */}}
{{- define "armonik.externalPostgresql.eventsConf" -}}
{{- $pg := list .Values "dependencies" "externalPostgresql" | include "armonik.utils.index" | fromYaml -}}
{{- if $pg.enabled }}
env:
  PostgreSQL__Host: {{ $pg.host | quote }}
  PostgreSQL__Port: {{ $pg.port | default 5432 | toString | quote }}
{{- end }}
{{- end -}}
