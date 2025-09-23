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
  {{- include "mongodb.fullname" . }}-headless.{{ include "mongodb.namespace" . }}.svc.{{ .Values.clusterDomain }}
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
Gets the configuration from mongodb forwarded to ArmoniK Core.
*/}}
{{- define "armonik.mongodb.conf" -}}
{{- $ctx := include "armonik.mongodb.context" . | fromYaml -}}
{{- if index $ctx.Values "enabled" -}}
env:
  Components__TableStorage:  "ArmoniK.Adapters.MongoDB.TableStorage"
  MongoDB__Host:             {{ include "armonik.mongodb.host" $ctx | quote }}
  MongoDB__Port:             {{ $ctx.Values.service.ports.mongodb | quote }}
  MongoDB__Tls:              {{ $ctx.Values.tls.enabled | quote }}
  MongoDB__ReplicaSet:       {{ $ctx.Values.replicaSetName | quote }}
  MongoDB__DatabaseName:     {{ include "armonik.mongodb.database" $ctx | quote }}
  MongoDB__DirectConnection: {{ $ctx.Values.architecture | eq "standalone" | quote }}
  MongoDB__AuthSource:       {{ include "armonik.mongodb.authSource" $ctx | quote }}
  MongoDB__User:             {{ $ctx.Values.auth.rootUser | quote }}
{{- if $ctx.Values.tls.enabled }}
  #MongoDB__CAFile:           "/mongodb/certificate/mongodb-ca-cert"
  MongoDB__AllowInsecureTls: "true"
{{- end }}
envFromSecret:
  MongoDB__Password:
    secret: {{ include "mongodb.secretName" $ctx }}
    field: mongodb-root-password
mountSecret:
{{- if $ctx.Values.tls.enabled }}
  mongodb-cert:
    secret: {{ include "mongodb.tlsSecretName" $ctx }}
    path: /mongodb/certificate/
    mode: "0444"
{{- end }}
{{- end }}
{{- end }}
