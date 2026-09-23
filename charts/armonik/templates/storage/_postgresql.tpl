{{/*
Read-write service of the Cluster. CNPG derives it from the Cluster name, itself taken from the
subchart's own helper rather than guessed, as armonik.mongodb.host does with psmdb-database.fullname.
*/}}
{{- define "armonik.postgresql.host" -}}
  {{- include "cluster.fullname" . }}-rw.{{ include "cluster.namespace" . }}.svc.{{ include "armonik.clusterDomain" . }}
{{- end -}}

{{/*
PostgreSQL's port. CNPG exposes no knob for it, so this is the literal 5432.
*/}}
{{- define "armonik.postgresql.port" -}}
  5432
{{- end -}}

{{/*
Database name. "app" is what CNPG itself creates when bootstrap.initdb.database is unset.
*/}}
{{- define "armonik.postgresql.database" -}}
  {{- list .Values "cluster" "initdb" "database" | include "armonik.utils.index" | default "app" -}}
{{- end -}}

{{/*
Secret the operator generates for the database owner, holding keys username and password. Named
<cluster>-app unless bootstrap.initdb.secret.name overrides it.
*/}}
{{- define "armonik.postgresql.secretName" -}}
  {{- $override := list .Values "cluster" "initdb" "secret" "name" | include "armonik.utils.index" -}}
  {{- $override | default (printf "%s-app" (include "cluster.fullname" .)) -}}
{{- end -}}

{{/*
Expand the namespace of the postgresql instance.
*/}}
{{- define "armonik.postgresql.namespace" -}}
  {{- include "cluster.namespace" . -}}
{{- end -}}

{{/*
PostgreSQL configuration forwarded to ArmoniK Core, derived from the in-cluster CloudNativePG Cluster. 
Skipped when that dependency is disabled: to bring your own PostgreSQL, set
dependencies.postgresql.enabled=false and supply the connection through the conf values directly
(conf.core.env / conf.core.envFromSecret). The postgres OPERATOR may be managed here or external
(global.armonik.operators.postgresOperator) - it does not affect this derivation, which reads the
Cluster's own rendered values.

Do not fix the mismatched spelling below: Components__TableStorage must equal
"ArmoniK.Adapters.PostgresSQL.TableStorage", an upstream typo matched literally by AddPostgresComponents.
Normalising either one silently unregisters the adaptor.
TODO: Core's PostgreSQL adaptor is still under development; re-check once it stabilizes there.

Ssl=true maps to Npgsql's SslMode.Require, which encrypts without validating the chain, so CNPG's own
CA needs no mountSecret here. A verify-full setup would mount <cluster>-ca like MongoDB__CAFile does.

Components__AuthenticationStorage must be stated: Core defaults it to the MongoDB table.
*/}}
{{- define "armonik.postgresql.conf" -}}
{{/* Live subchart scope via .Subcharts (armonik-dependencies is aliased "dependencies"); skipped when the dep is disabled. */}}
{{- with .Subcharts.dependencies.Subcharts.postgresql -}}
{{- $namespace := include "armonik.postgresql.namespace" . -}}
env:
  Components__TableStorage:          "ArmoniK.Adapters.PostgresSQL.TableStorage"
  Components__AuthenticationStorage: "ArmoniK.Adapters.PostgresSQL.AuthenticationTable"
  PostgreSQL__Host:                  {{ include "armonik.postgresql.host" . | quote }}
  PostgreSQL__Port:                  {{ include "armonik.postgresql.port" . | trim | quote }}
  PostgreSQL__DatabaseName:          {{ include "armonik.postgresql.database" . | quote }}
  PostgreSQL__Ssl:                   "true"
envFromSecret:
  PostgreSQL__User:
    secret: {{ include "armonik.postgresql.secretName" . }}
    field: username
    namespace: {{ $namespace | quote }}
  PostgreSQL__Password:
    secret: {{ include "armonik.postgresql.secretName" . }}
    field: password
    namespace: {{ $namespace | quote }}
{{- end }}
{{- end }}
