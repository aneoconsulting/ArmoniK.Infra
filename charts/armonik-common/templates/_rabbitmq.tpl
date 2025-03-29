{{/*
Gets the context to execute rabbitmq named templates

# Usage

{{ $ctx := include "armonik.rabbitmq.context" $ | fromYaml }}
*/}}
{{- define "armonik.rabbitmq.context" -}}
  {{- $context := . | deepCopy -}}
  {{/* Fetch rabbitmq Values from the global scope if it has been exported by the parent chart */}}
  {{- $_ := list .Values "global" "armonik-dependencies" "rabbitmq" | include "armonik.index" | fromYaml | set $context "Values" -}}
  {{/* Fake the content of `.Chart` to have the correct behavior when calling rabbitmq named template from outside mongo chart */}}
  {{- $_ := dict
      "IsRoot" .Chart.IsRoot
      "name" "rabbitmq"
      "type" "application"
    | set $context "Chart"
  -}}
  {{- $context | toYaml -}}
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
