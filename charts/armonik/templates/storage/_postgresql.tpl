{{/*
Connection to the PostgreSQL server, from dependencies.postgresql.connection.
*/}}
{{- define "armonik.postgresql.connection" -}}
  {{- list .Values "dependencies" "postgresql" "connection" | include "armonik.utils.index" -}}
{{- end -}}

{{/*
PostgreSQL configuration forwarded to ArmoniK Core, skipped without a host.
Components__AuthenticationStorage must be stated: Core defaults it to the MongoDB table.
*/}}
{{- define "armonik.postgresql.conf" -}}
{{- $conn := include "armonik.postgresql.connection" . | fromYaml -}}
{{- if $conn.host }}
{{- $credentials := $conn.credentials | default dict -}}
{{- $ref := required "dependencies.postgresql.connection.credentials.secret is required with a host" $credentials.secret | dict "secret" -}}
{{- range $key := list "namespace" "storeName" "storeKind" -}}
  {{- with index $credentials $key -}}
    {{- $_ := set $ref $key . -}}
  {{- end -}}
{{- end -}}
{{- $ssl := true -}}
{{- if kindIs "bool" $conn.ssl -}}
  {{- $ssl = $conn.ssl -}}
{{- end }}
env:
  Components__TableStorage:          "ArmoniK.Adapters.PostgreSQL.TableStorage"
  Components__AuthenticationStorage: "ArmoniK.Adapters.PostgreSQL.AuthenticationTable"
  PostgreSQL__Host:                  {{ $conn.host | quote }}
  PostgreSQL__Port:                  {{ $conn.port | default 5432 | toString | quote }}
  PostgreSQL__DatabaseName:          {{ required "dependencies.postgresql.connection.database is required with a host" $conn.database | quote }}
  PostgreSQL__Ssl:                   {{ $ssl | quote }}
envFromSecret:
  PostgreSQL__User:
    {{- $credentials.usernameField | default "username" | set (deepCopy $ref) "field" | toYaml | nindent 4 }}
  PostgreSQL__Password:
    {{- $credentials.passwordField | default "password" | set (deepCopy $ref) "field" | toYaml | nindent 4 }}
{{- end }}
{{- end -}}
