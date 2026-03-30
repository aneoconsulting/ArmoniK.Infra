{{/*
Gets the context to execute rabbitmq named templates

# Usage

{{ $ctx := include "armonik.rabbitmq.context" $ | fromYaml }}
*/}}
{{- define "armonik.rabbitmq.context" -}}
  {{- list . "rabbitmq" | include "armonik.dependencyContext" -}}
{{- end -}}

{{/*
Gets the hostname from rabbitmq context.
*/}}
{{- define "armonik.rabbitmq.host" -}}
  {{- include "common.names.fullname" . }}.{{ include "common.names.namespace" . }}.svc.{{ .Values.clusterDomain }}
{{- end -}}

{{/*
Gets the port from rabbitmq context.
*/}}
{{- define "armonik.rabbitmq.port" -}}
  {{- or (.Values.service.portEnabled) (not .Values.auth.tls.enabled) | ternary .Values.service.ports.amqp .Values.service.ports.amqpTls -}}
{{- end -}}

{{/*
Gets the configuration from rabbitmq forwarded to ArmoniK Core.
*/}}
{{- define "armonik.rabbitmq.conf" -}}
{{- $ctx := include "armonik.rabbitmq.context" . | fromYaml -}}
{{- if index $ctx.Values "enabled" -}}
env:
  Components__QueueAdaptorSettings__AdapterAbsolutePath: /adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll
  Components__QueueAdaptorSettings__ClassName: ArmoniK.Core.Adapters.Amqp.QueueBuilder
  Components__QueueStorage: ArmoniK.Adapters.Amqp.ObjectStorage

  Amqp__Host: {{ include "armonik.rabbitmq.host" $ctx | quote }}
  Amqp__Port: {{ include "armonik.rabbitmq.port" $ctx | quote }}
  Amqp__User: {{ $ctx.Values.auth.username | quote }}
  Amqp__MaxPriority: "10"
{{- if $ctx.Values.auth.tls.enabled }}
  Amqp__CaPath: /rabbitmq/certificate/ca.crt
  Amqp__Scheme: AMQPS
{{- else }}
  Amqp__Scheme: AMQP
{{- end }}

envFromSecret:
  Amqp__Password:
    secret: {{ include "rabbitmq.secretPasswordName" $ctx }}
    field: {{ include "rabbitmq.secretPasswordKey" $ctx }}
mountSecret:
{{- if $ctx.Values.auth.tls.enabled }}
  rabbitmq-cert:
    secret: {{ include "rabbitmq.tlsSecretName" $ctx }}
    path: /rabbitmq/certificate/
    mode: "0444"
{{- end }}
{{- end }}
{{- end }}
