{{/* Pod-template fragments: armonik.utils.patch parses what it patches, so each is a define. */}}

{{/* ActiveMQ broker container: amqp and dashboard ports, JVM heap from activemqOptsMemory. */}}
{{- define "activemq.container" -}}
{{- $v := .root.Values -}}
{{- $registry := $v.global.imageRegistry | default $v.image.registry -}}
name: activemq
{{- with $v.securityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- $tag := $v.image.tag | default .root.Chart.AppVersion }}
{{- if $registry }}
image: {{ printf "%s/%s:%s" $registry $v.image.repository $tag | quote }}
{{- else }}
image: {{ printf "%s:%s" $v.image.repository $tag | quote }}
{{- end }}
imagePullPolicy: {{ $v.image.pullPolicy | quote }}
ports:
  - containerPort: {{ $v.containerPort.amqp }}
    name: amqp
    protocol: TCP
  - containerPort: {{ $v.containerPort.dashboard }}
    name: dashboard
    protocol: TCP
env:
  - name: ACTIVEMQ_OPTS_MEMORY
    value: {{ $v.activemqOptsMemory }}
  {{- with $v.extraEnv }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- with $v.extraEnvFrom }}
envFrom:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.resources }}
resources:
  {{- toYaml . | nindent 2 }}
{{- end }}
volumeMounts:
  {{- with $v.extraVolumeMounts }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}


{{/* Broker pod spec: the patched container plus scheduling and the extra* additions. */}}
{{- define "activemq.podSpec" -}}
{{- $root := .root -}}
{{- $v := $root.Values -}}
{{- $container := list (include "activemq.container" .) $v.containerPatch "containerPatch" | include "armonik.utils.patch" | fromYaml -}}
{{- $containers := $v.extraContainers | default list | concat (list $container) -}}
{{- with $v.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers: {{- $containers | toYaml | nindent 2 }}
{{- with concat ($v.image.imagePullSecrets | default list) ($v.global.imagePullSecrets | default list) }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.extraVolumes }}
volumes:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with $v.priorityClassName }}
priorityClassName: {{ . | quote }}
{{- end }}
{{- with $v.topologySpreadConstraints }}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}
