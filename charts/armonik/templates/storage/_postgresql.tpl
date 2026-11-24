{{/*
The poolers entry named by corePooler, as YAML, empty when corePooler is. Fails on an entry Core
cannot run behind: Core writes, and runs multi-statement transactions that statement pooling splits.
*/}}
{{- define "armonik.postgresql.corePooler" -}}
  {{- $name := .Values.corePooler | default "" | toString -}}
  {{- if $name -}}
    {{- $entry := dict -}}
    {{- range $p := .Values.poolers | default list -}}
      {{- if eq ($p.name | toString) $name -}}
        {{- $entry = $p -}}
      {{- end -}}
    {{- end -}}
    {{- if empty $entry -}}
      {{- printf "dependencies.postgresql.corePooler=%q names no entry of dependencies.postgresql.poolers." $name | fail -}}
    {{- end -}}
    {{- if ne ($entry.type | default "rw" | toString) "rw" -}}
      {{- printf "dependencies.postgresql.poolers %q must have type rw: Core writes." $name | fail -}}
    {{- end -}}
    {{- if eq ($entry.poolMode | default "session" | toString) "statement" -}}
      {{- printf "dependencies.postgresql.poolers %q cannot use poolMode statement: Core runs multi-statement transactions. Use transaction." $name | fail -}}
    {{- end -}}
    {{- $entry | toYaml -}}
  {{- end -}}
{{- end -}}

{{/*
Host Core connects to: the read-write service of the Cluster, or the Pooler's service when corePooler
is set. CNPG derives both from the Cluster name, itself taken from the subchart's own helper.
*/}}
{{- define "armonik.postgresql.host" -}}
  {{- $pooler := include "armonik.postgresql.corePooler" . | fromYaml -}}
  {{- $service := empty $pooler | ternary "rw" (printf "pooler-%s" $pooler.name) -}}
  {{- include "cluster.fullname" . }}-{{ $service }}.{{ include "cluster.namespace" . }}.svc.{{ include "armonik.clusterDomain" . }}
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
(global.armonik.operators.postgresqlOperator).
*/}}
{{- define "armonik.postgresql.conf" -}}
{{/* Live subchart scope via .Subcharts (armonik-dependencies is aliased "dependencies"); skipped when the dep is disabled. */}}
{{- with .Subcharts.dependencies.Subcharts.postgresql -}}
  {{- $namespace := include "armonik.postgresql.namespace" . -}}
  {{- $ssl := kindIs "bool" .Values.ssl | ternary .Values.ssl true -}}
  {{- $host := include "armonik.postgresql.host" . -}}
  {{- /* The Pooler serves the Cluster's server certificate, which Core checks against the host name. The
         cert-manager Certificate lists the Pooler names itself (postgresql-certificate.yaml); the
         operator's own needs them in serverAltDNSNames. */ -}}
  {{- $certManager := list .Values "certManager" "enabled" | include "armonik.utils.index" | empty | not -}}
  {{- /* The operator authenticates its Poolers with a client certificate from its own CA, which a
         cert-manager clientCASecret no longer trusts. */ -}}
  {{- $pooler := include "armonik.postgresql.corePooler" . | fromYaml -}}
  {{- if and $pooler $certManager (not $pooler.authQuerySecret) -}}
    {{- printf "dependencies.postgresql.poolers %q needs authQuerySecret and authQuery with certManager.enabled: PostgreSQL then trusts only the cert-manager client CA and rejects the certificate the operator gives the Pooler. Set them up as the CloudNativePG Pooler documentation describes, or leave certManager.enabled=false." $pooler.name | fail -}}
  {{- end -}}
  {{- if and $ssl $pooler (not $certManager) -}}
    {{- $altNames := list .Values "cluster" "certificates" "serverAltDNSNames" | include "armonik.utils.index" | fromYamlArray -}}
    {{- if not (has $host $altNames) -}}
      {{- printf "dependencies.postgresql.cluster.certificates.serverAltDNSNames must list %q: Core reaches PostgreSQL through that Pooler and checks the server certificate's host name, which the operator only issues for the Cluster's own services." $host | fail -}}
    {{- end -}}
  {{- end -}}
  {{- $connection := dict
        "host" $host
        "port" (include "armonik.postgresql.port" . | trim)
        "database" (include "armonik.postgresql.database" .)
        "ssl" $ssl
        "credentials" (dict "secret" (include "armonik.postgresql.secretName" .) "namespace" $namespace)
        "ca" (dict "secret" (include "armonik.postgresql.caSecretName" .) "namespace" $namespace) }}
{{ list $connection $ | include "armonik.postgresqlConnection.conf" }}
{{- end }}
{{- end }}
