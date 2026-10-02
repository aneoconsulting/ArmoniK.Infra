{{/*
Configuration for an external PostgreSQL server (RDS, Cloud SQL, on-prem) forwarded to ArmoniK Core.
Components__AuthenticationStorage must be stated: Core defaults it to the MongoDB table.
*/}}
{{- define "armonik.externalPostgresql.conf" -}}
{{- $pg := list .Values "dependencies" "externalPostgresql" | include "armonik.utils.index" | fromYaml -}}
{{- if $pg.enabled }}
{{- $credentials := $pg.credentials | default dict -}}
{{- $_ := required "dependencies.externalPostgresql.credentials.secret is required when dependencies.externalPostgresql.enabled" $credentials.secret -}}
{{- $ssl := true -}}
{{- if kindIs "bool" $pg.ssl -}}
  {{- $ssl = $pg.ssl -}}
{{- end }}
env:
  Components__TableStorage:          "ArmoniK.Adapters.PostgreSQL.TableStorage"
  Components__AuthenticationStorage: "ArmoniK.Adapters.PostgreSQL.AuthenticationTable"
  PostgreSQL__Host:                  {{ required "dependencies.externalPostgresql.host is required when dependencies.externalPostgresql.enabled" $pg.host | quote }}
  PostgreSQL__Port:                  {{ $pg.port | default 5432 | toString | quote }}
  PostgreSQL__DatabaseName:          {{ required "dependencies.externalPostgresql.database is required when dependencies.externalPostgresql.enabled" $pg.database | quote }}
  PostgreSQL__Ssl:                   {{ $ssl | quote }}
envFromSecret:
  PostgreSQL__User:
    {{- $credentials.usernameField | default "username" | set (pick $credentials "secret" "namespace" "storeName" "storeKind") "field" | toYaml | nindent 4 }}
  PostgreSQL__Password:
    {{- $credentials.passwordField | default "password" | set (pick $credentials "secret" "namespace" "storeName" "storeKind") "field" | toYaml | nindent 4 }}
{{- end }}
{{- end -}}
