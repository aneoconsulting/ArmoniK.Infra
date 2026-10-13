{{/*
Read-write service of the Cluster. CNPG derives it from the Cluster name, itself taken from the
subchart's own helper
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
Secret holding the server certificate's CA under ca.crt: cluster.certificates.serverCASecret, else
<cluster>-ca, the operator's own.
*/}}
{{- define "armonik.postgresql.caSecretName" -}}
  {{- $override := list .Values "cluster" "certificates" "serverCASecret" | include "armonik.utils.index" -}}
  {{- $override | default (printf "%s-ca" (include "cluster.fullname" .)) -}}
{{- end -}}

{{/*
Expand the namespace of the postgresql instance.
*/}}
{{- define "armonik.postgresql.namespace" -}}
  {{- include "cluster.namespace" . -}}
{{- end -}}

{{/*
PostgreSQL configuration forwarded to ArmoniK Core, derived from the in-cluster CloudNativePG Cluster,
through armonik.postgresqlConnection.conf. The postgres OPERATOR may be managed here or external
(global.armonik.operators.postgresqlOperator) - it does not affect this derivation, which reads the
Cluster's own rendered values.
*/}}
{{- define "armonik.postgresql.conf" -}}
{{/* Live subchart scope via .Subcharts (armonik-dependencies is aliased "dependencies"); skipped when the dep is disabled. */}}
{{- with .Subcharts.dependencies.Subcharts.postgresql -}}
  {{- $namespace := include "armonik.postgresql.namespace" . -}}
  {{- $connection := dict
        "host" (include "armonik.postgresql.host" .)
        "port" (include "armonik.postgresql.port" . | trim)
        "database" (include "armonik.postgresql.database" .)
        "ssl" true
        "credentials" (dict "secret" (include "armonik.postgresql.secretName" .) "namespace" $namespace)
        "ca" (dict "secret" (include "armonik.postgresql.caSecretName" .) "namespace" $namespace) }}
{{ list $connection $ | include "armonik.postgresqlConnection.conf" }}
{{- end }}
{{- end }}
