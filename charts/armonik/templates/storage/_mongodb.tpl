{{/*
Gets the hostname from mongodb context. The DNS suffix must match what the Percona operator
provisions for the replica-set Service, so it mirrors the psmdb-db chart's clusterServiceDNSSuffix
(which already includes the "svc." segment); its default equals the operator default (svc.cluster.local).
This is intentionally driven by the mongodb chart mechanism, NOT by global.armonik.clusterDomain.
*/}}
{{- define "armonik.mongodb.host" -}}
  {{- include "psmdb-database.fullname" . }}-{{ .Values.replsets.rs0.name | default "rs0" }}.{{ include "psmdb-database.namespace" . }}.{{ .Values.clusterServiceDNSSuffix | default "svc.cluster.local" }}
{{- end -}}

{{/*
Gets the database name from mongodb context.
*/}}
{{- define "armonik.mongodb.database" -}}
  database
{{- end -}}

{{/*
Gets the authentication source from mongodb context.
*/}}
{{- define "armonik.mongodb.authSource" -}}
  admin
{{- end -}}

{{/*
Returns whether MongoDB requires tls from mongodb context
*/}}
{{- define "armonik.mongodb.requireTls" -}}
  enabled: {{ not .Values.unsafeFlags.tls }}
{{- end -}}

{{/*
Returns the Secret's name created by Percona's MongoDB Helm chart according
to https://github.com/percona/percona-helm-charts/blob/main/charts/psmdb-db/templates/cluster-secret.yaml#L5
since no such partial is defined in the chart helpers
*/}}
{{- define "armonik.mongodb.secretName" }}
  {{- include "psmdb-database.fullname" . }}-secrets
{{- end }}

{{/*
Returns the port of rs0 replica set, as indicated by the documentation, https://docs.percona.com/percona-operator-for-mongodb/custom-install.html?h=port#configure-ports-for-mongodb-cluster-components
By default set to 27017.
*/}}
{{- define "armonik.mongodb.port" }}
  {{- $config := list .Values "replsets" "rs0" "configuration" | include "armonik.utils.index" | fromYaml }}
  {{- list $config "net" "port" | include "armonik.utils.index" | default "27017" -}}
{{- end }}
{{/*
MongoDB configuration forwarded to ArmoniK Core, derived from the in-cluster Percona MongoDB (the
psmdb-db dependency). Skipped when that dependency is disabled: to bring your own MongoDB, set
dependencies.mongodb.enabled=false and supply the connection through the conf values directly
(conf.core.env / conf.core.envFromSecret). The mongodb OPERATOR may be managed here or external
(global.armonik.operators.mongodbOperator) - it does not affect this derivation, which reads the
psmdb-db instance's own rendered values.
*/}}
{{- define "armonik.mongodb.conf" -}}
{{- $root := . -}}
{{- $prefix := "mongodb-" -}}
{{/* Live subchart scope via .Subcharts (armonik-dependencies is aliased "dependencies"); skipped when the dep is disabled. */}}
{{- with .Subcharts.dependencies.Subcharts.mongodb -}}
{{- $requireTls := (include "armonik.mongodb.requireTls" . | fromYaml).enabled -}}
env:
  Components__TableStorage:  "ArmoniK.Adapters.MongoDB.TableStorage"
  MongoDB__Host:             {{ include "armonik.mongodb.host" . | quote }}
  MongoDB__Port:             {{ include "armonik.mongodb.port" . | quote }}
  MongoDB__Tls:              {{ $requireTls | quote }}
  MongoDB__ReplicaSet:       {{ .Values.replsets.rs0.name | quote }}
  MongoDB__DatabaseName:     {{ include "armonik.mongodb.database" . | quote }}
  MongoDB__DirectConnection: {{ (.Values.replsets.rs0.size | default 3 | quote) | eq "1" | quote }}
  MongoDB__AuthSource:       {{ include "armonik.mongodb.authSource" . | quote }}
  MongoDB__AllowInsecureTls: "true"
{{- if $requireTls }}
  MongoDB__CAFile:           {{ list $prefix "ca.crt" $root | include "armonik.conf.mountFilePath" | quote }}
{{- end }}
envFromSecret:
  MongoDB__User:
    secret: {{ include "armonik.mongodb.secretName" . }}
    field: MONGODB_DATABASE_ADMIN_USER
  MongoDB__Password:
    secret: {{ include "armonik.mongodb.secretName" . }}
    field: MONGODB_DATABASE_ADMIN_PASSWORD
mountSecret:
{{- $internalTlsSecret := list .Values "secrets" "sslInternal" | include "armonik.utils.index" -}}
{{- if and $requireTls $internalTlsSecret }}
  - secret: {{ $internalTlsSecret | quote }}
    prefix: {{ $prefix | quote }}
{{- end }}
{{- end }}
{{- end }}
