{{/*
valkey Service hostname. Takes the redis (valkey) subchart scope, as do the other helpers here except
armonik.redis.conf, which takes the root.
*/}}
{{- define "armonik.redis.host" -}}
  {{- include "valkey.fullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.clusterDomain -}}
{{- end -}}

{{/*
valkey Service port.
*/}}
{{- define "armonik.redis.port" -}}
  {{- .Values.service.port }}
{{- end -}}

{{/*
Namespace of the valkey instance: the release one, valkey having no namespace key.
*/}}
{{- define "armonik.redis.namespace" -}}
  {{- .Release.Namespace -}}
{{- end }}

{{/*
Core conf for the in-cluster valkey: env, password reference and, with TLS, the TLS Secret mount.
*/}}
{{- define "armonik.redis.conf" -}}
{{- $root := . -}}
{{- $prefix := "redis-" -}}
{{/* Skipped when the dependency is disabled (.Subcharts holds enabled ones only). */}}
{{- with .Subcharts.dependencies.Subcharts.redis -}}
{{- $namespace := include "armonik.redis.namespace" . -}}
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
  Redis__CaPath:       {{ list $prefix .Values.tls.caPublicKey $root | include "armonik.conf.mountFilePath" | quote }}
{{- end }}
envFromSecret:
  Redis__Password:
    secret: {{ tpl .Values.auth.usersExistingSecret . | quote }}
    field: default
    namespace: {{ $namespace | quote }}
mountSecret:
{{- if .Values.tls.enabled }}
  - secret: {{ .Values.tls.existingSecret }}
    prefix: {{ $prefix | quote }}
    namespace: {{ $namespace | quote }}
{{- end }}
{{- end }}
{{- end }}
