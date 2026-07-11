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
{{/* Live subchart scope via .Subcharts (armonik-dependencies is aliased "dependencies"); skipped when the dep is disabled. */}}
{{- with .Subcharts.dependencies.Subcharts.redis -}}
env:
  Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath: /adapters/object/redis/ArmoniK.Core.Adapters.Redis.dll
  Components__ObjectStorageAdaptorSettings__ClassName: ArmoniK.Core.Adapters.Redis.ObjectBuilder
  Components__ObjectStorage: ArmoniK.Adapters.Redis.ObjectStorage

  Redis__EndpointUrl:  {{ include "armonik.redis.host" . }}:{{ include "armonik.redis.port" . }}
  Redis__InstanceName: ArmoniKRedis
  Redis__ClientName:   ArmoniK.Core
  Redis__User:         "default"
  Redis__Ssl:          {{ .Values.tls.enabled | quote }}
{{- if .Values.tls.enabled }}
  Redis__CaPath:       /mounts/redis-{{ .Values.tls.caPublicKey }}
{{- end }}
envFromSecret:
  Redis__Password:
    secret: redis-users
    field: default
mountSecret:
{{- if .Values.tls.enabled }}
  redis:
    secret: {{ .Values.tls.existingSecret }}
{{- end }}
{{- end }}
{{- end }}
