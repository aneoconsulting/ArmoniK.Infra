{{/*
Gets the context to execute activemq named templates

# Usage

{{ $ctx := include "armonik.activemq.context" $ | fromYaml }}
*/}}
{{- define "armonik.activemq.context" -}}
  {{- $context := . | deepCopy -}}
  {{/* Fetch activemq Values from the global scope if it has been exported by the parent chart */}}
  {{- $_ := list .Values "global" "armonik-dependencies" "activemq" | include "armonik.index" | fromYaml | set $context "Values" -}}
  {{/* Fake the content of `.Chart` to have the correct behavior when calling activemq named template from outside mongo chart */}}
  {{- $_ := dict
      "IsRoot" .Chart.IsRoot
      "name" "activemq"
      "type" "application"
    | set $context "Chart"
  -}}
  {{- $context | toYaml -}}
{{- end -}}

{{/*
Gets the configuration from activemq forwarded to ArmoniK Core.
*/}}
{{- define "armonik.activemq.conf" -}}
{{- $ctx := include "armonik.activemq.context" . | fromYaml -}}
{{- if index $ctx.Values "enabled" -}}
env:
  Components__QueueAdaptorSettings__AdapterAbsolutePath: /adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll
  Components__QueueAdaptorSettings__ClassName: ArmoniK.Core.Adapters.Amqp.QueueBuilder
  Amqp__Host:        {{ include "activemq.fullname" $ctx | quote }}
  Amqp__Port:        {{ $ctx.Values.containerPort.amqp | quote }}
  Amqp__Scheme:      AMQP
  Amqp__User:        admin
  Amqp__Password:    admin
  Amqp__MaxPriority: "10"
{{- end }}
{{- end }}
