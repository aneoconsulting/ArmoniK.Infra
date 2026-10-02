{{/*
Replica-set hostname. Takes the psmdb-db subchart scope, as do the armonik.mongodb.* helpers below
except armonik.mongodb.conf, which takes the root. The suffix is psmdb-db's clusterServiceDNSSuffix
(which includes "svc."), matching what the operator provisions, deliberately not global.clusterDomain.
*/}}
{{- define "armonik.mongodb.host" -}}
  {{- include "psmdb-database.fullname" . }}-{{ list .Values "replsets" "rs0" "name" | include "armonik.utils.index" | default "rs0" }}.{{ include "psmdb-database.namespace" . }}.{{ .Values.clusterServiceDNSSuffix | default "svc.cluster.local" }}
{{- end -}}

{{/*
Database name.
*/}}
{{- define "armonik.mongodb.database" -}}
  database
{{- end -}}

{{/*
Authentication database.
*/}}
{{- define "armonik.mongodb.authSource" -}}
  admin
{{- end -}}

{{/*
"enabled: <bool>": TLS is required unless unsafeFlags.tls is set.
*/}}
{{- define "armonik.mongodb.requireTls" -}}
  enabled: {{ list .Values "unsafeFlags" "tls" | include "armonik.utils.index" | empty }}
{{- end -}}

{{/*
Name of the users Secret psmdb-db creates, which the chart exposes through no helper:
https://github.com/percona/percona-helm-charts/blob/main/charts/psmdb-db/templates/cluster-secret.yaml#L5
*/}}
{{- define "armonik.mongodb.secretName" }}
  {{- include "psmdb-database.fullname" . }}-secrets
{{- end }}

{{/*
Port of the rs0 replica set, 27017 unless its configuration sets net.port:
https://docs.percona.com/percona-operator-for-mongodb/custom-install.html?h=port#configure-ports-for-mongodb-cluster-components
*/}}
{{- define "armonik.mongodb.port" }}
  {{- $config := list .Values "replsets" "rs0" "configuration" | include "armonik.utils.index" | fromYaml }}
  {{- list $config "net" "port" | include "armonik.utils.index" | default "27017" -}}
{{- end }}

{{/*
Namespace of the psmdb-db instance.
*/}}
{{- define "armonik.mongodb.namespace" -}}
  {{- include "psmdb-database.namespace" . -}}
{{- end }}
{{/*
Core conf for the in-cluster psmdb-db: env, credential references and, with TLS, the TLS Secret mount.
To bring your own MongoDB, set dependencies.mongodb.enabled=false and supply the connection through
conf.core.env / conf.core.envFromSecret. Where the operator runs does not matter here.
*/}}
{{- define "armonik.mongodb.conf" -}}
{{- $root := . -}}
{{- $prefix := "mongodb-" -}}
{{/* Skipped when the dependency is disabled (.Subcharts holds enabled ones only). */}}
{{- with .Subcharts.dependencies.Subcharts.mongodb -}}
{{- $requireTls := (include "armonik.mongodb.requireTls" . | fromYaml).enabled -}}
{{- $namespace := include "armonik.mongodb.namespace" . -}}
env:
  Components__TableStorage:  "ArmoniK.Adapters.MongoDB.TableStorage"
  MongoDB__Host:             {{ include "armonik.mongodb.host" . | quote }}
  MongoDB__Port:             {{ include "armonik.mongodb.port" . | quote }}
  MongoDB__Tls:              {{ $requireTls | quote }}
  MongoDB__ReplicaSet:       {{ list .Values "replsets" "rs0" "name" | include "armonik.utils.index" | default "rs0" | quote }}
  MongoDB__DatabaseName:     {{ include "armonik.mongodb.database" . | quote }}
  MongoDB__DirectConnection: {{ (list .Values "replsets" "rs0" "size" | include "armonik.utils.index" | default 3 | quote) | eq "1" | quote }}
  MongoDB__AuthSource:       {{ include "armonik.mongodb.authSource" . | quote }}
  MongoDB__AllowInsecureTls: "true"
{{- if $requireTls }}
  MongoDB__CAFile:           {{ list $prefix "ca.crt" $root | include "armonik.conf.mountFilePath" | quote }}
{{- end }}
envFromSecret:
  MongoDB__User:
    secret: {{ include "armonik.mongodb.secretName" . }}
    field: MONGODB_DATABASE_ADMIN_USER
    namespace: {{ $namespace | quote }}
  MongoDB__Password:
    secret: {{ include "armonik.mongodb.secretName" . }}
    field: MONGODB_DATABASE_ADMIN_PASSWORD
    namespace: {{ $namespace | quote }}
mountSecret:
{{- $internalTlsSecret := list .Values "secrets" "sslInternal" | include "armonik.utils.index" -}}
{{- if and $requireTls $internalTlsSecret }}
  - secret: {{ $internalTlsSecret | quote }}
    prefix: {{ $prefix | quote }}
    namespace: {{ $namespace | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
mongodb-exporter's namespace: the release one, its chart having no namespace key. Takes its subchart scope.
*/}}
{{- define "armonik.mongodbExporter.namespace" -}}
  {{- .Release.Namespace -}}
{{- end -}}

{{/*
{consumer, remote}: namespaces of the mongodb-exporter ExternalSecret and of the MongoDB Secrets it
reads, for secret-store.yaml. Empty when either dependency is disabled. Takes the root.
*/}}
{{- define "armonik.mongodbExporter.storeReads" -}}
  {{- with index .Subcharts.dependencies.Subcharts "mongodb-exporter" -}}
    {{- $consumer := include "armonik.mongodbExporter.namespace" . -}}
    {{- with $.Subcharts.dependencies.Subcharts.mongodb }}
consumer: {{ $consumer | quote }}
remote: {{ include "armonik.mongodb.namespace" . | quote }}
    {{- end -}}
  {{- end -}}
{{- end -}}
