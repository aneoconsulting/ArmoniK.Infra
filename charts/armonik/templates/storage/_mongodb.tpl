{{/*
Gets the hostname from mongodb context.
*/}}
{{- define "armonik.mongodb.host" -}}
  {{- include "psmdb-database.fullname" . }}-{{ .Values.replsets.rs0.name | default "rs0" }}.{{ include "psmdb-database.namespace" . }}.svc.{{ .Values.clusterServiceDNSSuffix | default "cluster.local" }}
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
  {{- $port := list .Values.replsets.rs0 "configuration" "net" "port" | include "armonik.utils.index" | fromYaml }}
  {{- $port | default "27017" -}}
{{- end }}
{{/*
Gets the configuration from mongodb forwarded to ArmoniK Core.
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
{{- $internalTlsSecret := list .Values "secrets" "sslInternal" | include "armonik.utils.index" | fromYaml -}}
{{- if and $requireTls $internalTlsSecret }}
  mongodb:
    secret: {{ $internalTlsSecret }}
    prefix: {{ $prefix | quote }}
{{- end }}
{{- end }}
{{- end }}
