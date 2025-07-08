{{- define "armonik.queue" -}}
  {{- if .Values.global.dependencies.rabbitmq }}
  Amqp__Host: rabbitmq
  {{- else if .Values.global.dependencies.activemq }}
  Amqp__Host: activemq
  {{- else }}
  Amqp__Host: localhost
  {{- end }}
{{- end }}
