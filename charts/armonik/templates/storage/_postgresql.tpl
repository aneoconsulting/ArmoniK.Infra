{{/*
Connection to the PostgreSQL server, from dependencies.postgresql.connection.
*/}}
{{- define "armonik.postgresql.connection" -}}
  {{- list .Values "dependencies" "postgresql" "connection" | include "armonik.utils.index" -}}
{{- end -}}

{{/*
PostgreSQL configuration forwarded to ArmoniK Core.
Components__AuthenticationStorage must be stated: Core defaults it to the MongoDB table.
*/}}
{{- define "armonik.postgresql.conf" -}}
{{- if list .Values "dependencies" "postgresql" "enabled" | include "armonik.utils.index" }}
{{- $conn := include "armonik.postgresql.connection" . | fromYaml -}}
{{- $credentials := $conn.credentials | default dict -}}
{{- $_ := required "dependencies.postgresql.connection.credentials.secret is required when dependencies.postgresql.enabled" $credentials.secret -}}
{{- $ssl := true -}}
{{- if kindIs "bool" $conn.ssl -}}
  {{- $ssl = $conn.ssl -}}
{{- end }}
env:
  Components__TableStorage:          "ArmoniK.Adapters.PostgreSQL.TableStorage"
  Components__AuthenticationStorage: "ArmoniK.Adapters.PostgreSQL.AuthenticationTable"
  PostgreSQL__Host:                  {{ required "dependencies.postgresql.connection.host is required when dependencies.postgresql.enabled" $conn.host | quote }}
  PostgreSQL__Port:                  {{ $conn.port | default 5432 | toString | quote }}
  PostgreSQL__DatabaseName:          {{ required "dependencies.postgresql.connection.database is required when dependencies.postgresql.enabled" $conn.database | quote }}
  PostgreSQL__Ssl:                   {{ $ssl | quote }}
envFromSecret:
  PostgreSQL__User:
    {{- $credentials.usernameField | default "username" | set (pick $credentials "secret" "namespace" "storeName" "storeKind") "field" | toYaml | nindent 4 }}
  PostgreSQL__Password:
    {{- $credentials.passwordField | default "password" | set (pick $credentials "secret" "namespace" "storeName" "storeKind") "field" | toYaml | nindent 4 }}
{{- end }}
{{- end -}}
