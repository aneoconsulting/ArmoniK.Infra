{{/*
Gets the context to execute redis named templates

# Usage

{{ $ctx := include "armonik.redis.context" $ | fromYaml }}
*/}}
{{- define "armonik.redis.context" -}}
  {{- list . "redis" | include "armonik.dependencyContext" -}}
{{- end -}}

{{/*
Gets the hostname from redis context.
*/}}
{{- define "armonik.redis.host" -}}
  {{- if eq .Values.architecture "replication" | and .Values.sentinel.enabled -}}
    {{- include "common.names.fullname" . }}.{{ include "common.names.namespace" . }}.svc.{{ .Values.clusterDomain -}}
  {{- else -}}
    {{- include "common.names.fullname" . }}-master.{{ include "common.names.namespace" . }}.svc.{{ .Values.clusterDomain -}}
  {{- end -}}
{{- end -}}

{{/*
Gets the port from redis context.
*/}}
{{- define "armonik.redis.port" -}}
  {{- if eq .Values.architecture "replication" | and .Values.sentinel.enabled -}}
    {{- .Values.sentinel.service.ports.sentinel -}}
  {{- else -}}
    {{- .Values.master.service.ports.redis -}}
  {{- end -}}
{{- end -}}

{{/*
Gets the configuration from redis forwarded to ArmoniK Core.
*/}}
{{- define "armonik.redis.conf" -}}
{{- $ctx := include "armonik.redis.context" . | fromYaml -}}
{{- if index $ctx.Values "enabled" -}}
env:
  Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath: /adapters/object/redis/ArmoniK.Core.Adapters.Redis.dll
  Components__ObjectStorageAdaptorSettings__ClassName: ArmoniK.Core.Adapters.Redis.ObjectBuilder
  Components__ObjectStorage: ArmoniK.Adapters.Redis.ObjectStorage

  Redis__EndpointUrl:  {{ include "armonik.redis.host" $ctx }}:{{ include "armonik.redis.port" $ctx }}
  Redis__InstanceName: ArmoniKRedis
  Redis__ClientName:   ArmoniK.Core
  Redis__User:         ""
  Redis__Ssl:          {{ $ctx.Values.tls.enabled | quote }}
{{- if $ctx.Values.tls.enabled }}
  Redis__CaPath:       /redis/certificate/{{ include "redis.createTlsSecret" $ctx | empty | ternary $ctx.Values.tls.certCAFilename "ca.crt" }}
{{- end }}
envFromSecret:
  Redis__Password:
    secret: {{ include "redis.secretName" $ctx }}
    field: {{ include "redis.secretPasswordKey" $ctx }}
mountSecret:
{{- if $ctx.Values.tls.enabled }}
  redis-cert:
    secret: {{ include "redis.tlsSecretName" $ctx }}
    path: /redis/certificate/
    mode: "0444"
{{- end }}
{{- end }}
{{- end }}
