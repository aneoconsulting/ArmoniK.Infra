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
  {{- include "valkey.fullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.clusterDomain -}}
{{- end -}}

{{/*
Gets the port from redis context.
*/}}
{{- define "armonik.redis.port" -}}
  {{- .Values.service.port }}
{{- end -}}

{{/*
Gets the configuration from redis forwarded to ArmoniK Core.
*/}}
{{- define "armonik.redis.conf" -}}
{{- $ctx := include "armonik.redis.context" . | fromYaml -}}
{{- if $ctx.Values.enabled -}}
env:
  Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath: /adapters/object/redis/ArmoniK.Core.Adapters.Redis.dll
  Components__ObjectStorageAdaptorSettings__ClassName: ArmoniK.Core.Adapters.Redis.ObjectBuilder
  Components__ObjectStorage: ArmoniK.Adapters.Redis.ObjectStorage

  Redis__EndpointUrl:  {{ include "armonik.redis.host" $ctx }}:{{ include "armonik.redis.port" $ctx }}
  Redis__InstanceName: ArmoniKRedis
  Redis__ClientName:   ArmoniK.Core
  Redis__User:         "default"
  Redis__Ssl:          {{ $ctx.Values.tls.enabled | quote }}
{{- if $ctx.Values.tls.enabled }}
  Redis__CaPath:       /redis/certificate/{{ $ctx.Values.tls.caPublicKey }}
{{- end }}
envFromSecret:
  Redis__Password:
    secret: redis-users
    field: default
mountSecret:
{{- if $ctx.Values.tls.enabled }}
  redis-cert:
    secret: {{ $ctx.Values.tls.existingSecret }}
    path: /redis/certificate/
    mode: "0444"
{{- end }}
{{- end }}
{{- end }}
