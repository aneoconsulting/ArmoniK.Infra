{{/*
Gets the context to execute mongodb named templates

# Usage

{{ $ctx := include "armonik.mongodb.context" $ | fromYaml }}
*/}}
{{- define "armonik.mongodb.context" -}}
  {{- list . "mongodb" | include "armonik.dependencyContext" -}}
{{- end -}}

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
  {{- $port := include "armonik.utils.index" (list .Values.replsets.rs0 "configuration" "net" "port") | fromYaml }}
  {{- $port | default "27017" -}}
{{- end }}
{{/*
Gets the configuration from mongodb forwarded to ArmoniK Core.
*/}}
{{- define "armonik.mongodb.conf" -}}
{{- $ctx := include "armonik.mongodb.context" . | fromYaml -}}
{{- if $ctx.Values.enabled -}}
{{- $requireTls := (include "armonik.mongodb.requireTls" $ctx | fromYaml).enabled -}}
env:
  Components__TableStorage:  "ArmoniK.Adapters.MongoDB.TableStorage"
  MongoDB__Host:             {{ include "armonik.mongodb.host" $ctx | quote }}
  MongoDB__Port:             {{ include "armonik.mongodb.port" $ctx | quote }}
  MongoDB__Tls:              {{ $requireTls | quote }}
  MongoDB__ReplicaSet:       {{ $ctx.Values.replsets.rs0.name | quote }}
  MongoDB__DatabaseName:     {{ include "armonik.mongodb.database" . | quote }}
  MongoDB__DirectConnection: {{ ($ctx.Values.replsets.rs0.size | default 3 | quote) | eq "1" | quote }}
  MongoDB__AuthSource:       {{ include "armonik.mongodb.authSource" . | quote }}
  MongoDB__AllowInsecureTls: "true"
{{- if $requireTls }}
  MongoDB__CAFile:           "/mongodb/certificate/mongodb-ca-cert"
{{- end }}
envFromSecret:
  MongoDB__User:
    secret: {{ include "armonik.mongodb.secretName" $ctx }}
    field: MONGODB_DATABASE_ADMIN_USER
  MongoDB__Password:
    secret: {{ include "armonik.mongodb.secretName" $ctx }}
    field: MONGODB_DATABASE_ADMIN_PASSWORD
mountSecret:
{{- $internalTlsSecret := include "armonik.utils.index" (list $ctx.Values "secrets" "sslInternal") | fromYaml -}}
{{- if and $requireTls $internalTlsSecret }}
  mongodb-cert:
    secret: {{ $internalTlsSecret }}
    path: /mongodb/certificate/
    mode: "0444"
{{- end }}
{{- end }}
{{- end }}
