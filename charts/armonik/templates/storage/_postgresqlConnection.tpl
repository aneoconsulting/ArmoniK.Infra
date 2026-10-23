{{/*
Core conf for a PostgreSQL connection, shared by armonik.postgresql.conf (in-cluster) and
armonik.externalPostgresql.conf (cloud), which build and validate it.
Components__AuthenticationStorage must be stated: Core defaults it to the MongoDB table.
With ssl, Core validates the server certificate against CAFile.
Input: list <connection> $ (the umbrella root, for armonik.conf.mountFilePath)
  connection.host         server host name
  connection.port         default 5432
  connection.database     database name
  connection.ssl          bool; true sets CAFile and mounts ca.crt from connection.ca
  connection.credentials  {secret, namespace, storeName, storeKind, usernameField, passwordField},
                          fields default to username/password
  connection.ca           {secret, field, namespace, storeName, storeKind}, field defaults to ca.crt;
                          read only with ssl
Usage: {{ list $connection $ | include "armonik.postgresqlConnection.conf" }}
*/}}
{{- define "armonik.postgresqlConnection.conf" -}}
{{- $pg := index . 0 -}}
{{- $root := index . 1 -}}
{{- $credentials := $pg.credentials | default dict -}}
{{- $prefix := "postgresql-" -}}
env:
  Components__TableStorage:          "ArmoniK.Adapters.PostgreSQL.TableStorage"
  Components__AuthenticationStorage: "ArmoniK.Adapters.PostgreSQL.AuthenticationTable"
  PostgreSQL__Host:                  {{ $pg.host | quote }}
  PostgreSQL__Port:                  {{ $pg.port | default 5432 | toString | quote }}
  PostgreSQL__DatabaseName:          {{ $pg.database | quote }}
  PostgreSQL__Ssl:                   {{ $pg.ssl | quote }}
{{- /* Pending Core release: keeps idle replication slots for reuse.
  PostgreSQL__ReplicationIdleTimeout: "00:05:00"
*/}}
{{- if $pg.ssl }}
  PostgreSQL__CAFile:                {{ list $prefix "ca.crt" $root | include "armonik.conf.mountFilePath" | quote }}
{{- end }}
envFromSecret:
  PostgreSQL__User:
    {{- $credentials.usernameField | default "username" | set (pick $credentials "secret" "namespace" "storeName" "storeKind") "field" | toYaml | nindent 4 }}
  PostgreSQL__Password:
    {{- $credentials.passwordField | default "password" | set (pick $credentials "secret" "namespace" "storeName" "storeKind") "field" | toYaml | nindent 4 }}
{{- if $pg.ssl }}
{{- $ca := $pg.ca | default dict -}}
{{- $source := pick $ca "secret" "namespace" "storeName" "storeKind" | merge (dict "prefix" $prefix) }}
mountSecret:
  {{- /* Only ca.crt: a CA Secret may also hold the CA's private key. */}}
  - {{- dict "ca.crt" (dict "field" ($ca.field | default "ca.crt")) | set $source "items" | toYaml | nindent 4 }}
{{- end }}
{{- end -}}
