{{/*
Render context for activemq templates: the root-visible .Values.dependencies.activemq tree.

# Usage

{{ $ctx := include "armonik.activemq.context" $ | fromYaml }}
*/}}
{{- define "armonik.activemq.context" -}}
  {{- list . "activemq" | include "armonik.rootDependencyContext" -}}
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
